﻿// <copyright file="BuildArguments.cs" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

using Opal;
using System.Collections.Generic;

namespace Soup.Build.CSharp.Compiler
{
	/// <summary>
	/// The enumeration of build optimization levels
	/// </summary>
	public enum BuildOptimizationLevel
	{
		/// <summary>
		/// Debug
		/// </summary>
		None,

		/// <summary>
		/// Optimize for runtime speed, may sacrifice size
		/// </summary>
		Speed,

		/// <summary>
		/// Optimize for speed and size
		/// </summary>
		Size,
	}

	/// <summary>
	/// The enumeration of target types
	/// </summary>
	public enum BuildTargetType
	{
		/// <summary>
		/// Executable
		/// </summary>
		Executable,

		/// <summary>
		/// Library
		/// </summary>
		Library,
	}

	/// <summary>
	/// The enumeration of nullable state
	/// </summary>
	public enum BuildNullableState
	{
		/// <summary>
		/// Enabled
		/// </summary>
		Enabled,

		/// <summary>
		/// Disabled
		/// </summary>
		Disabled,

		/// <summary>
		/// Annotations
		/// </summary>
		Annotations,

		/// <summary>
		/// Warnings
		/// </summary>
		Warnings,
	}

	/// <summary>
	/// The set of build arguments
	/// </summary>
	public class BuildArguments
	{
		/// <summary>
		/// Gets or sets the target name
		/// </summary>
		public string TargetName { get; set; } = string.Empty;

		/// <summary>
		/// Gets or sets the target architecture
		/// </summary>
		public string TargetArchitecture { get; set; } = string.Empty;

		/// <summary>
		/// Gets or sets the target type
		/// </summary>
		public BuildTargetType TargetType { get; set; }

		/// <summary>
		/// Gets or sets the source directory
		/// </summary>
		public Path SourceRootDirectory { get; set; } = new Path();

		/// <summary>
		/// Gets or sets the target directory
		/// </summary>
		public Path TargetRootDirectory { get; set; } = new Path();

		/// <summary>
		/// Gets or sets the output object directory
		/// </summary>
		public Path ObjectDirectory { get; set; } = new Path();

		/// <summary>
		/// Gets or sets the output binary directory
		/// </summary>
		public Path BinaryDirectory { get; set; } = new Path();

		/// <summary>
		/// Gets or sets the list of source files
		/// </summary>
		public IReadOnlyList<Path> SourceFiles { get; set; } = new List<Path>();

		/// <summary>
		/// Gets or sets the list of link libraries
		/// </summary>
		public IReadOnlyList<Path> LinkDependencies { get; set; } = new List<Path>();

		/// <summary>
		/// Gets or sets the list of library paths
		/// </summary>
		public IReadOnlyList<Path> LibraryPaths { get; set; } = new List<Path>();

		/// <summary>
		/// Gets or sets the list of preprocessor definitions
		/// </summary>
		public IReadOnlyList<string> PreprocessorDefinitions { get; set; } = new List<string>();

		/// <summary>
		/// Gets or sets the list of runtime dependencies
		/// </summary>
		public IReadOnlyList<Path> RuntimeDependencies { get; set; } = new List<Path>();

		/// <summary>
		/// Gets or sets the optimization level
		/// </summary>
		public BuildOptimizationLevel OptimizationLevel { get; set; }

		/// <summary>
		/// Gets or sets a value indicating whether to generate source debug information
		/// </summary>
		public bool GenerateSourceDebugInfo { get; set; }

		/// <summary>
		/// Gets or sets a value indicating whether to enable warnings as errors
		/// </summary>
		public bool EnableWarningsAsErrors { get; set; }

		/// <summary>
		/// Gets or sets a the nullable state
		/// </summary>
		public BuildNullableState NullableState { get; set; }

		/// <summary>
		/// Gets or sets the list of disabled warnings
		/// </summary>
		public IReadOnlyList<string> DisabledWarnings { get; set; } = new List<string>();

		/// <summary>
		/// Gets or sets the list of enabled warnings
		/// </summary>
		public IReadOnlyList<string> EnabledWarnings { get; set; } = new List<string>();

		/// <summary>
		/// Gets or sets the set of custom properties for the known compiler
		/// </summary>
		public IReadOnlyList<string> CustomProperties { get; set; } = new List<string>();
	}
}
