﻿// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "mwasplund|Soup.Build.Utils:./ListExtensions" for ListExtensions
import "mwasplund|Soup.Build.Utils:./MapExtensions" for MapExtensions
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "mwasplund|Soup.Build.Utils:./SemanticVersion" for SemanticVersion

/// <summary>
/// The recipe build task that knows how to build a single recipe
/// </summary>
class ResolveToolsTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
		"BuildTask",
	] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [
		"InitializeDefaultsTask",
	] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState

		ResolveToolsTask.LoadDotNet(globalState, activeState)
	}

	static LoadDotNet(globalState, activeState) {
		var build = activeState["Build"]
		var architecture = build["Architecture"]

		// Check if skip platform includes was specified
		var skipPlatform = false
		if (activeState.containsKey("SkipPlatform")) {
			skipPlatform = activeState["SkipPlatform"]
		}

		// Get the DotNet SDK
		var dotnetSDKProperties = ResolveToolsTask.GetSDKProperties("DotNet", globalState)

		// Get the latest .net 6 sdk
		var sdk = ResolveToolsTask.GetLatestSDK(dotnetSDKProperties)
		var sdkVersion = sdk["version"]
		var sdkPath = sdk["path"] + Path.new("%(sdkVersion)")

		// Get the latest .net 6 targeting pack
		var targetingPack = ResolveToolsTask.GetLatestTargetingPack(dotnetSDKProperties, 6, "Microsoft.NETCore.App.Ref")
		var targetingPackVersion = targetingPack["version"]
		var targetingPackVersionPath = targetingPack["path"] + Path.new("%(targetingPackVersion)/ref/net6.0/")

		// Reference the dotnet executable
		var dotNetExecutable = Path.new(dotnetSDKProperties["DotNetExecutable"])

		// Load the roslyn library compiler reference
		var cscToolPath = sdkPath + Path.new("Roslyn/bincore/csc.dll")

		// Save the build properties
		var roslyn = MapExtensions.EnsureTable(activeState, "Roslyn")
		roslyn["CscToolPath"] = cscToolPath.toString

		var dotnet = MapExtensions.EnsureTable(activeState, "DotNet")
		dotnet["ExecutablePath"] = dotNetExecutable.toString
		dotnet["TargetingPackVersion"] = targetingPack["version"].toString
		dotnet["TargetingPackPath"] = targetingPackVersionPath.toString

		// Save the platform libraries
		activeState["PlatformLibraries"] = ""
		var linkDependencies = []
		if (build.containsKey("LinkDependencies")) {
			linkDependencies = ListExtensions.ConvertToPathList(build["LinkDependencies"])
		}

		linkDependencies = linkDependencies + ResolveToolsTask.GetPlatformLibraries(targetingPackVersionPath)
		build["LinkDependencies"] = ListExtensions.ConvertFromPathList(linkDependencies)
	}

	static GetPlatformLibraries(targetingPackVersionPath) {
		// Set the platform libraries
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

		var result = []
		for (value in platformLibraries) {
			result.add(targetingPackVersionPath + value)
		}

		return result
	}

	static GetSDKProperties(name, globalState) {
		for (sdk in globalState["SDKs"]) {
			if (sdk.containsKey("Name")) {
				var nameValue = sdk["Name"]
				if (nameValue == name) {
					return sdk["Properties"]
				}
			}
		}

		Fiber.abort("Missing SDK %(name)")
	}

	static GetLatestSDK(properties) {
		if (!properties.containsKey("SDKs")) {
			Fiber.abort("Missing DotNet SDK SDKs")
		}

		var sdks = properties["SDKs"]

		var bestVersion
		var bestVersionValue
		var bestVersionPath
		for (sdk in sdks) {
			var sdkVersion = ResolveToolsTask.ParseSemanticVersionWithExtras(sdk.key)
			if (bestVersion is Null || sdkVersion > bestVersion) {
				bestVersion = sdkVersion
				bestVersionValue = sdk.key
				bestVersionPath = Path.new(sdk.value)
			}
		}

		if (bestVersion is Null) {
			Fiber.abort("Missing DotNet SDK SDKs for version %(majorVersion)")
		}

		return { "version": bestVersionValue, "path": bestVersionPath } 
	}

	static GetLatestTargetingPack(properties, majorVersion, targetingPackName) {
		if (!properties.containsKey("TargetingPacks")) {
			Fiber.abort("Missing DotNet SDK TargetingPacks")
		}

		var packs = properties["TargetingPacks"]
		if (!packs.containsKey(targetingPackName)) {
			Fiber.abort("Missing DotNet SDK Targeting TargetingPacks Type %(targetingPackName)")
		}

		var targetingPackVersions = packs[targetingPackName]
		var bestVersion
		var bestVersionPath
		for (targetingPack in targetingPackVersions) {
			var targetingPackVersion = ResolveToolsTask.ParseSemanticVersionWithExtras(targetingPack.key)
			if (targetingPackVersion.Major == majorVersion) {
				if (bestVersion is Null || targetingPackVersion > bestVersion) {
					bestVersion = targetingPackVersion
					bestVersionPath = Path.new(targetingPack.value)
				}
			}
		}

		if (bestVersion is Null) {
			Fiber.abort("Missing DotNet SDK TargetingPacks Type %(targetingPackName) for version %(majorVersion)")
		}

		return { "version": bestVersion, "path": bestVersionPath } 
	}

	static ParseSemanticVersionWithExtras(value) {
		// Ignore the extras if present
		var versionExtraValues = value.split("-")

		// Parse the integer values
		var stringValues = versionExtraValues[0].split(".")
		if (stringValues.count < 1) {
			Fiber.abort("The version string must have one to three values.")
		}

		var intValues = []
		for (stringValue in stringValues) {
			var intValue = Num.fromString(stringValue)
			if (!(intValue is Null)) {
				intValues.add(intValue)
			} else {
				Fiber.abort("Invalid version string: \"%(value)\"")
			}
		}

		var major = intValues[0]

		var minor = null
		if (intValues.count >= 2) {
			minor = intValues[1]
		}

		var patch = null
		if (intValues.count >= 3) {
			patch = intValues[2]
		}

		return SemanticVersion.new(
			major,
			minor,
			patch)
	}
}
