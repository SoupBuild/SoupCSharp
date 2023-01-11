﻿// <copyright file="BuildEngine.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The build engine
/// </summary>
class BuildEngine {
	BuildEngine(ICompiler compiler) {
		_compiler = compiler
	}

	/// <summary>
	/// Generate the required build operations for the requested build
	/// </summary>
	BuildResult Execute(
		IBuildState buildState,
		BuildArguments arguments) {
		var result = new BuildResult()

		// Ensure the output directories exists as the first step
		var referenceDirectory = arguments.BinaryDirectory + new Path("ref/")
		result.BuildOperations.Add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				arguments.ObjectDirectory))
		result.BuildOperations.Add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				arguments.BinaryDirectory))
		result.BuildOperations.Add(
			SharedOperations.CreateCreateDirectoryOperation(
				arguments.TargetRootDirectory,
				referenceDirectory))

		// Perform the core compilation of the source files
		CoreCompile(buildState, arguments, referenceDirectory, result)

		// Copy previous runtime dependencies after linking has completed
		CopyRuntimeDependencies(arguments, result)

		GenerateBuildRuntimeConfigurationFiles(arguments, result)

		return result
	}

	/// <summary>
	/// Compile the source files
	/// </summary>
	private void CoreCompile(
		IBuildState buildState,
		BuildArguments arguments,
		Path referenceDirectory,
		BuildResult result) {
		// Ensure there are actually files to build
		if (arguments.SourceFiles.Count != 0) {
			Path targetFile
			Path referenceTargetFile
			LinkTarget targetType
			switch (arguments.TargetType)
			{
				case BuildTargetType.Library:
					targetType = LinkTarget.Library
					targetFile =
						arguments.BinaryDirectory +
						new Path(arguments.TargetName + "." + _compiler.DynamicLibraryFileExtension)
					referenceTargetFile =
						referenceDirectory +
						new Path(arguments.TargetName + "." + _compiler.DynamicLibraryFileExtension)

					// Add the DLL as a runtime dependency
					result.RuntimeDependencies.Add(arguments.TargetRootDirectory + targetFile)

					// Link against the reference target
					result.LinkDependencies.Add(arguments.TargetRootDirectory + referenceTargetFile)

					break
				case BuildTargetType.Executable:
					targetType = LinkTarget.Executable
					targetFile =
						arguments.BinaryDirectory +
						new Path(arguments.TargetName + "." + _compiler.DynamicLibraryFileExtension)
					referenceTargetFile =
						referenceDirectory +
						new Path(arguments.TargetName + "." + _compiler.DynamicLibraryFileExtension)

					// Add the Executable as a runtime dependency
					result.RuntimeDependencies.Add(arguments.TargetRootDirectory + targetFile)

					// All link dependencies stop here.

					break
				default:
					throw new InvalidOperationException("Unknown build target type.")
			}

			// Convert the nullable state
			NullableState nullableState
			switch (arguments.NullableState)
			{
				case BuildNullableState.Disabled:
					nullableState = NullableState.Disabled
					break
				case BuildNullableState.Enabled:
					nullableState = NullableState.Enabled
					break
				case BuildNullableState.Warnings:
					nullableState = NullableState.Warnings
					break
				case BuildNullableState.Annotations:
					nullableState = NullableState.Annotations
					break
				default:
					throw new InvalidOperationException("Unknown Nullable State")
			}

			// Setup the shared properties
			var compileArguments = new CompileArguments()
			{
				Target = targetFile,
				ReferenceTarget = referenceTargetFile,
				TargetType = targetType,
				SourceRootDirectory = arguments.SourceRootDirectory,
				TargetRootDirectory = arguments.TargetRootDirectory,
				ObjectDirectory = arguments.ObjectDirectory,
				SourceFiles = arguments.SourceFiles,
				PreprocessorDefinitions = arguments.PreprocessorDefinitions,
				GenerateSourceDebugInfo = arguments.GenerateSourceDebugInfo,
				EnableWarningsAsErrors = arguments.EnableWarningsAsErrors,
				DisabledWarnings = arguments.DisabledWarnings,
				EnabledWarnings = arguments.EnabledWarnings,
				NullableState = nullableState,
				CustomProperties = arguments.CustomProperties,
				ReferenceLibraries = arguments.LinkDependencies,
			}

			// Compile all source files as a single call
			var compileOperations = _compiler.CreateCompileOperations(compileArguments)
			foreach (var operation in compileOperations)
				result.BuildOperations.Add(operation)

			result.TargetFile = arguments.TargetRootDirectory + targetFile
		}
	}

	/// <summary>
	/// Copy runtime dependencies
	/// </summary>
	private void CopyRuntimeDependencies(
		BuildArguments arguments,
		BuildResult result)
	{
		if (arguments.TargetType == BuildTargetType.Executable ||
			arguments.TargetType == BuildTargetType.Library)
		{
			// TODO: Allow build libraries to copy dependencies with a flag
			// for now we always copy the dlls so the folder is ready to load dependencies
			foreach (var source in arguments.RuntimeDependencies)
			{
				var target = arguments.BinaryDirectory + new Path(source.GetFileName())
				var operation = SharedOperations.CreateCopyFileOperation(
					arguments.TargetRootDirectory,
					source,
					target)
				result.BuildOperations.Add(operation)
			}
		}

		if (arguments.TargetType != BuildTargetType.Executable)
		{
			// Pass along all runtime dependencies in their original location
			foreach (var source in arguments.RuntimeDependencies)
			{
				result.RuntimeDependencies.Add(source)
			}
		}
	}

	/// <summary>
	/// Generate Build Runtime Configuration Files
	/// </summary>
	private void GenerateBuildRuntimeConfigurationFiles(
		BuildArguments arguments,
		BuildResult result)
	{
		if (arguments.TargetType == BuildTargetType.Executable)
		{
			// Generate the runtime configuration files
			var runtimeConfigFile = arguments.BinaryDirectory + new Path($"{arguments.TargetName}.runtimeconfig.json")
			var content =
@"{
""runtimeOptions"": {
""tfm"": ""net6.0"",
""framework"": {
	""name"": ""Microsoft.NETCore.App"",
	""version"": ""6.0.0""
},
""configProperties"": {
	""System.Reflection.Metadata.MetadataUpdater.IsSupported"": false
}
}
}"
			var writeRuntimeConfigFile = SharedOperations.CreateWriteFileOperation(
				arguments.TargetRootDirectory,
				runtimeConfigFile,
				content)
			result.BuildOperations.Add(writeRuntimeConfigFile)
		}
	}

	private ICompiler _compiler
}
