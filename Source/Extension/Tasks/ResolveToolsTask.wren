﻿// <copyright file="ResolveToolsTask.wren", company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The recipe build task that knows how to build a single recipe
/// </summary>
class ResolveToolsTask : IBuildTask
{
	IBuildState buildState
	IValueFactory factory

	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
	{
	}

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [
	{
	}

	ResolveToolsTask(IBuildState buildState, IValueFactory factory)
	{
		this.buildState = buildState
		this.factory = factory
	}

	/// <summary>
	/// The Core Execute task
	/// </summary>
	Execute()
	{
		var state = this.buildState.ActiveState
		var parameters = state["Parameters"].AsTable()
		var buildTable = state.EnsureValueTable(this.factory, "Build")

		var systemName = parameters["System"].AsString()
		var architectureName = parameters["Architecture"].AsString()

		if (systemName != "win32")
			Fiber.abort("Win32 is the only supported system... so far.")

		// Check if skip platform includes was specified
		bool skipPlatform = false
		if (state.TryGetValue("SkipPlatform", out var skipPlatformValue))
		{
			skipPlatform = skipPlatformValue.AsBoolean()
		}

		// Find the Roslyn SDK
		var roslynSDKProperties = GetSDKProperties("Roslyn", parameters)

		// Calculate the final Roslyn binaries folder
		var roslynFolder = Path.new(roslynSDKProperties["ToolsRoot"].AsString())

		var cscToolPath = roslynFolder + Path.new("csc.exe")

		// Get the DotNet SDK
		var dotnetSDKProperties = GetSDKProperties("DotNet", parameters)
		var dotnetRuntimeVersion = SemanticVersion.Parse(dotnetSDKProperties["RuntimeVersion"].AsString())
		var dotnetRootPath = Path.new(dotnetSDKProperties["RootPath"].AsString())

		// Save the build properties
		state["Roslyn.BinRoot"] = this.factory.Create(roslynFolder.toString)
		state["Roslyn.CscToolPath"] = this.factory.Create(cscToolPath.toString)
		state["DotNet.RuntimeVersion"] = this.factory.Create(dotnetRuntimeVersion.toString)
		state["DotNet.RootPath"] = this.factory.Create(dotnetRootPath.toString)

		// Save the platform libraries
		state["PlatformLibraries"] = this.factory.Create("")
		var linkDependencies = [
		if (buildTable.TryGetValue("LinkDependencies", out var linkLibrariesValue))
		{
			linkDependencies = linkLibrariesValue.AsList().Select(value { Path.new(value.AsString())).ToList()
		}

		linkDependencies.AddRange(GetPlatformLibraries(dotnetRootPath, dotnetRuntimeVersion))
		buildTable["LinkDependencies"] = this.factory.Create(
			this.factory.CreateList().SetAll(this.factory, linkDependencies))
	}

	IEnumerable<Path> GetPlatformLibraries(Path dotnetRootPath, SemanticVersion dotnetRuntimeVersion)
	{
		// Set the platform libraries
		var path = dotnetRootPath + Path.new("packs/Microsoft.NETCore.App.Ref/%(dotnetRuntimeVersion)/ref/net6.0/")
		var platformLibraries = [
			Path.new("Microsoft.CSharp.dll"),
			Path.new("Microsoft.VisualBasic.Core.dll"),
			Path.new("Microsoft.VisualBasic.dll"),
			Path.new("Microsoft.Win32.Primitives.dll"),
			Path.new("mscorlib.dll"),
			Path.new("netstandard.dll"),
			Path.new("System.AppContext.dll"),
			Path.new("System.Buffers.dll"),
			Path.new("System.Collections.Concurrent.dll"),
			Path.new("System.Collections.dll"),
			Path.new("System.Collections.Immutable.dll"),
			Path.new("System.Collections.NonGeneric.dll"),
			Path.new("System.Collections.Specialized.dll"),
			Path.new("System.ComponentModel.Annotations.dll"),
			Path.new("System.ComponentModel.DataAnnotations.dll"),
			Path.new("System.ComponentModel.dll"),
			Path.new("System.ComponentModel.EventBasedAsync.dll"),
			Path.new("System.ComponentModel.Primitives.dll"),
			Path.new("System.ComponentModel.TypeConverter.dll"),
			Path.new("System.Configuration.dll"),
			Path.new("System.Console.dll"),
			Path.new("System.Core.dll"),
			Path.new("System.Data.Common.dll"),
			Path.new("System.Data.DataSetExtensions.dll"),
			Path.new("System.Data.dll"),
			Path.new("System.Diagnostics.Contracts.dll"),
			Path.new("System.Diagnostics.Debug.dll"),
			Path.new("System.Diagnostics.DiagnosticSource.dll"),
			Path.new("System.Diagnostics.FileVersionInfo.dll"),
			Path.new("System.Diagnostics.Process.dll"),
			Path.new("System.Diagnostics.StackTrace.dll"),
			Path.new("System.Diagnostics.TextWriterTraceListener.dll"),
			Path.new("System.Diagnostics.Tools.dll"),
			Path.new("System.Diagnostics.TraceSource.dll"),
			Path.new("System.Diagnostics.Tracing.dll"),
			Path.new("System.dll"),
			Path.new("System.Drawing.dll"),
			Path.new("System.Drawing.Primitives.dll"),
			Path.new("System.Dynamic.Runtime.dll"),
			Path.new("System.Formats.Asn1.dll"),
			Path.new("System.Globalization.Calendars.dll"),
			Path.new("System.Globalization.dll"),
			Path.new("System.Globalization.Extensions.dll"),
			Path.new("System.IO.Compression.Brotli.dll"),
			Path.new("System.IO.Compression.dll"),
			Path.new("System.IO.Compression.FileSystem.dll"),
			Path.new("System.IO.Compression.ZipFile.dll"),
			Path.new("System.IO.dll"),
			Path.new("System.IO.FileSystem.dll"),
			Path.new("System.IO.FileSystem.DriveInfo.dll"),
			Path.new("System.IO.FileSystem.Primitives.dll"),
			Path.new("System.IO.FileSystem.Watcher.dll"),
			Path.new("System.IO.IsolatedStorage.dll"),
			Path.new("System.IO.MemoryMappedFiles.dll"),
			Path.new("System.IO.Pipes.dll"),
			Path.new("System.IO.UnmanagedMemoryStream.dll"),
			Path.new("System.Linq.dll"),
			Path.new("System.Linq.Expressions.dll"),
			Path.new("System.Linq.Parallel.dll"),
			Path.new("System.Linq.Queryable.dll"),
			Path.new("System.Memory.dll"),
			Path.new("System.Net.dll"),
			Path.new("System.Net.Http.dll"),
			Path.new("System.Net.Http.Json.dll"),
			Path.new("System.Net.HttpListener.dll"),
			Path.new("System.Net.Mail.dll"),
			Path.new("System.Net.NameResolution.dll"),
			Path.new("System.Net.NetworkInformation.dll"),
			Path.new("System.Net.Ping.dll"),
			Path.new("System.Net.Primitives.dll"),
			Path.new("System.Net.Requests.dll"),
			Path.new("System.Net.Security.dll"),
			Path.new("System.Net.ServicePoint.dll"),
			Path.new("System.Net.Sockets.dll"),
			Path.new("System.Net.WebClient.dll"),
			Path.new("System.Net.WebHeaderCollection.dll"),
			Path.new("System.Net.WebProxy.dll"),
			Path.new("System.Net.WebSockets.Client.dll"),
			Path.new("System.Net.WebSockets.dll"),
			Path.new("System.Numerics.dll"),
			Path.new("System.Numerics.Vectors.dll"),
			Path.new("System.ObjectModel.dll"),
			Path.new("System.Reflection.DispatchProxy.dll"),
			Path.new("System.Reflection.dll"),
			Path.new("System.Reflection.Emit.dll"),
			Path.new("System.Reflection.Emit.ILGeneration.dll"),
			Path.new("System.Reflection.Emit.Lightweight.dll"),
			Path.new("System.Reflection.Extensions.dll"),
			Path.new("System.Reflection.Metadata.dll"),
			Path.new("System.Reflection.Primitives.dll"),
			Path.new("System.Reflection.TypeExtensions.dll"),
			Path.new("System.Resources.Reader.dll"),
			Path.new("System.Resources.ResourceManager.dll"),
			Path.new("System.Resources.Writer.dll"),
			Path.new("System.Runtime.CompilerServices.Unsafe.dll"),
			Path.new("System.Runtime.CompilerServices.VisualC.dll"),
			Path.new("System.Runtime.dll"),
			Path.new("System.Runtime.Extensions.dll"),
			Path.new("System.Runtime.Handles.dll"),
			Path.new("System.Runtime.InteropServices.dll"),
			Path.new("System.Runtime.InteropServices.RuntimeInformation.dll"),
			Path.new("System.Runtime.Intrinsics.dll"),
			Path.new("System.Runtime.Loader.dll"),
			Path.new("System.Runtime.Numerics.dll"),
			Path.new("System.Runtime.Serialization.dll"),
			Path.new("System.Runtime.Serialization.Formatters.dll"),
			Path.new("System.Runtime.Serialization.Json.dll"),
			Path.new("System.Runtime.Serialization.Primitives.dll"),
			Path.new("System.Runtime.Serialization.Xml.dll"),
			Path.new("System.Security.Claims.dll"),
			Path.new("System.Security.Cryptography.Algorithms.dll"),
			Path.new("System.Security.Cryptography.Csp.dll"),
			Path.new("System.Security.Cryptography.Encoding.dll"),
			Path.new("System.Security.Cryptography.Primitives.dll"),
			Path.new("System.Security.Cryptography.X509Certificates.dll"),
			Path.new("System.Security.dll"),
			Path.new("System.Security.Principal.dll"),
			Path.new("System.Security.SecureString.dll"),
			Path.new("System.ServiceModel.Web.dll"),
			Path.new("System.ServiceProcess.dll"),
			Path.new("System.Text.Encoding.CodePages.dll"),
			Path.new("System.Text.Encoding.dll"),
			Path.new("System.Text.Encoding.Extensions.dll"),
			Path.new("System.Text.Encodings.Web.dll"),
			Path.new("System.Text.Json.dll"),
			Path.new("System.Text.RegularExpressions.dll"),
			Path.new("System.Threading.Channels.dll"),
			Path.new("System.Threading.dll"),
			Path.new("System.Threading.Overlapped.dll"),
			Path.new("System.Threading.Tasks.Dataflow.dll"),
			Path.new("System.Threading.Tasks.dll"),
			Path.new("System.Threading.Tasks.Extensions.dll"),
			Path.new("System.Threading.Tasks.Parallel.dll"),
			Path.new("System.Threading.Thread.dll"),
			Path.new("System.Threading.ThreadPool.dll"),
			Path.new("System.Threading.Timer.dll"),
			Path.new("System.Transactions.dll"),
			Path.new("System.Transactions.Local.dll"),
			Path.new("System.ValueTuple.dll"),
			Path.new("System.Web.dll"),
			Path.new("System.Web.HttpUtility.dll"),
			Path.new("System.Windows.dll"),
			Path.new("System.Xml.dll"),
			Path.new("System.Xml.Linq.dll"),
			Path.new("System.Xml.ReaderWriter.dll"),
			Path.new("System.Xml.Serialization.dll"),
			Path.new("System.Xml.XDocument.dll"),
			Path.new("System.Xml.XmlDocument.dll"),
			Path.new("System.Xml.XmlSerializer.dll"),
			Path.new("System.Xml.XPath.dll"),
			Path.new("System.Xml.XPath.XDocument.dll"),
			Path.new("WindowsBase.dll"),
		]

		return platformLibraries.Select(value { path + value)
	}

	IValueTable GetSDKProperties(string name, IValueTable state) {
		foreach (var sdk in state["SDKs"].AsList())
		{
			var sdkTable = sdk.AsTable()
			if (sdkTable.TryGetValue("Name", out var nameValue))
			{
				if (nameValue.AsString() == name)
				{
					return sdkTable["Properties"].AsTable()
				}
			}
		}

		Fiber.abort("Missing SDK %(name)")
	}
}