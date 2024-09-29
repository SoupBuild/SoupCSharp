// <copyright file="RoslynCompilerUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "mwasplund|Soup.CSharp.Compiler:./CompileOptions" for CompileOptions, LinkTarget, NullableState
import "mwasplund|Soup.CSharp.Compiler.Roslyn:./RoslynCompiler" for RoslynCompiler
import "mwasplund|Soup.Build.Utils:./BuildOperation" for BuildOperation
import "mwasplund|Soup.Build.Utils:./Path" for Path
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
			Path.new("C:/bin/mock.dotnet.exe"),
			Path.new("C:/lib/mock.csc.dll"))
		Assert.Equal("Roslyn", uut.Name)
		Assert.Equal("obj", uut.ObjectFileExtension)
		Assert.Equal("lib", uut.StaticLibraryFileExtension)
		Assert.Equal("dll", uut.DynamicLibraryFileExtension)
	}

	// [Fact]
	Compile_Simple() {
		var uut = RoslynCompiler.new(
			Path.new("C:/bin/mock.dotnet.exe"),
			Path.new("C:/lib/mock.csc.dll"))

		var options = CompileOptions.new()
		options.Target = Path.new("bin/Target.dll")
		options.TargetType = LinkTarget.Library
		options.ReferenceTarget = Path.new("ref/Target.dll")
		options.SourceRootDirectory = Path.new("C:/source/")
		options.TargetRootDirectory = Path.new("C:/target/")
		options.ObjectDirectory = Path.new("ObjectDir/")
		options.SourceFiles = [
			Path.new("File.cs"),
		]
		options.NullableState =  NullableState.Enabled

		var result = uut.CreateCompileOperations(options)

		// Verify result
		var expected = [
			BuildOperation.new(
				"WriteFile [./ObjectDir/CompileArguments.rsp]",
				Path.new("C:/target/"),
				Path.new("./writefile.exe"),
				[
					"./ObjectDir/CompileArguments.rsp",
					"/unsafe- /checked- /fullpaths /nostdlib+ /errorreport:prompt /warn:5 /errorendlocation /preferreduilang:en-US /highentropyva+ /nullable:enable /debug+ /debug:portable /filealign:512 /optimize- /out:\"C:/target/bin/Target.dll\" /refout:\"C:/target/ref/Target.dll\" /target:library /warnaserror- /utf8output /deterministic+ /langversion:9.0 \"./File.cs\"",
				],
				[],
				[
					Path.new("./ObjectDir/CompileArguments.rsp"),
				]),
			BuildOperation.new(
				"Compile - ./bin/Target.dll",
				Path.new("C:/source/"),
				Path.new("C:/bin/mock.dotnet.exe"),
				[
					"exec",
					"C:/lib/mock.csc.dll",
					"@C:/target/ObjectDir/CompileArguments.rsp",
					"/noconfig",
				],
				[
					Path.new("C:/lib/mock.csc.dll"),
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
