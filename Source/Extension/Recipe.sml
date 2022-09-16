Name: "Soup.CSharp"
Language: "C#|0.1"
Version: "0.6.0"

Source: [
	"Tasks/BuildTask.cs"
	"Tasks/RecipeBuildTask.cs"
	"Tasks/ResolveDependenciesTask.cs"
	"Tasks/ResolveToolsTask.cs"
]

Dependencies: {
	Runtime: [
		{ Reference: "Opal@1.1.0", }
		{ Reference: "Soup.Build@0.1.4", ExcludeRuntime: true, }
		{ Reference: "Soup.Build.Extensions@0.2.0", }
		{ Reference: "Soup.Build.Extensions.Utilities@0.2.1", }
		{ Reference: "Soup.CSharp.Compiler@0.4.2", }
		{ Reference: "Soup.CSharp.Compiler.Roslyn@0.4.1", }
	]
}