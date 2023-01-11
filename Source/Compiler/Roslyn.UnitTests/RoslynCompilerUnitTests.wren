// <copyright file="RoslynCompilerUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "../Core/CompileArguments" for CompileArguments, LinkTarget, NullableState
import "../Roslyn/RoslynCompiler" for RoslynCompiler
import "../../Utils/BuildOperation" for BuildOperation
import "../../Utils/Path" for Path
import "../../Test/Assert" for Assert

class RoslynCompilerUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("RoslynCompilerUnitTests.Initialize")
		this.Initialize()
		System.print("RoslynCompilerUnitTests.Compile_Simple")
		this.Compile_Simple()
	}

	// [Fact]
	Initialize() {
		var uut = RoslynCompiler.new(
			Path.new("C:/bin/mock.csc.exe"))
		Assert.Equal("Roslyn", uut.Name)
		Assert.Equal("obj", uut.ObjectFileExtension)
		Assert.Equal("lib", uut.StaticLibraryFileExtension)
		Assert.Equal("dll", uut.DynamicLibraryFileExtension)
	}

	// [Fact]
	Compile_Simple() {
		var uut = RoslynCompiler.new(
			Path.new("C:/bin/mock.csc.exe"))

		var arguments = CompileArguments.new()
		arguments.Target = Path.new("bin/Target.dll")
		arguments.TargetType = LinkTarget.Library
		arguments.ReferenceTarget = Path.new("ref/Target.dll")
		arguments.SourceRootDirectory = Path.new("C:/source/")
		arguments.TargetRootDirectory = Path.new("C:/target/")
		arguments.ObjectDirectory = Path.new("ObjectDir/")
		arguments.SourceFiles = [
			Path.new("File.cs"),
		]
		arguments.NullableState =  NullableState.Enabled

		var result = uut.CreateCompileOperations(arguments)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/CompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				"\"./ObjectDir/CompileArguments.rsp\" \"/unsafe- /checked- /fullpaths /nostdlib+ /errorreport:prompt /warn:5 /errorendlocation /preferreduilang:en-US /highentropyva+ /nullable:enable /debug+ /debug:portable /filealign:512 /optimize- /out:\"C:/target/bin/Target.dll\" /refout:\"C:/target/ref/Target.dll\" /target:library /warnaserror- /utf8output /deterministic+ /langversion:9.0 \"./File.cs\"\"",
				[],
				[
					Path.new("./ObjectDir/CompileArguments.rsp"),
				]),
			BuildOperation.new(
				"Compile - ./bin/Target.dll",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.csc.exe"),
				"@C:/target/ObjectDir/CompileArguments.rsp /noconfig",
				[
					Path.new("C:/target/ObjectDir/CompileArguments.rsp"),
					Path.new("./File.cs"),
				],
				[
					Path.new("C:/target/bin/Target.dll"),
					Path.new("C:/target/bin/Target.pdb"),
				]),
		]

		Assert.ListEqual(expected, result)
	}
}