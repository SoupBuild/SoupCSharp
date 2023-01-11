﻿// <copyright file="ResolveToolsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

/// <summary>
/// The resolve dependencies build task that knows how to combine all previous state
/// into the active state.
/// </summary>
class ResolveDependenciesTask : IBuildTask
{
	private IBuildState buildState
	private IValueFactory factory

	/// <summary>
	/// Get the run before list
	/// </summary>
	static IReadOnlyList<string> RunBeforeList => new List<string>()
	{
		"BuildTask",
	}

	/// <summary>
	/// Get the run after list
	/// </summary>
	static IReadOnlyList<string> RunAfterList => new List<string>()
	{
	}

	ResolveDependenciesTask(IBuildState buildState, IValueFactory factory)
	{
		this.buildState = buildState
		this.factory = factory
	}

	/// <summary>
	/// The Core Execute task
	/// </summary>
	void Execute()
	{
		var activeState = this.buildState.ActiveState
		var recipeTable = activeState["Recipe"].AsTable()
		var parametersTable = activeState["Parameters"].AsTable()
		var buildTable = activeState.EnsureValueTable(this.factory, "Build")

		if (activeState.TryGetValue("Dependencies", out var dependenciesValue))
		{
			var dependenciesTable = dependenciesValue.AsTable()
			if (dependenciesTable.TryGetValue("Runtime", out var runtimeValue))
			{
				var runtimeDependenciesTable = runtimeValue.AsTable()

				foreach (var dependencyName in runtimeDependenciesTable.Keys)
				{
					// Combine the core dependency build inputs for the core build task
					this.buildState.LogTrace(TraceLevel.Information, "Combine Runtime Dependency: " + dependencyName)
					var dependencyTable = runtimeDependenciesTable[dependencyName].AsTable()

					if (dependencyTable.TryGetValue("Build", out var buildValue))
					{
						var dependencyBuildTable = buildValue.AsTable()
						var dependencyReference = GetRuntimeDependencyParameterReference(parametersTable, dependencyName)
						var dependencyRecipeReference = GetRuntimeDependencyReference(recipeTable, dependencyReference)

						if (!dependencyRecipeReference.ExcludeRuntime)
						{
							if (dependencyBuildTable.TryGetValue("RuntimeDependencies", out var runtimeDependenciesValue))
							{
								var runtimeDependencies = runtimeDependenciesValue.AsList()
								buildTable.EnsureValueList(this.factory, "RuntimeDependencies").Append(runtimeDependencies)
							}
						}
						else
						{
							this.buildState.LogTrace(TraceLevel.Information, $"Excluding Runtime dependency content: {dependencyName}")
						}

						if (dependencyBuildTable.TryGetValue("LinkDependencies", out var linkDependenciesValue))
						{
							var linkDependencies = linkDependenciesValue.AsList()
							buildTable.EnsureValueList(this.factory, "LinkDependencies").Append(linkDependencies)
						}
					}
				}
			}
		}
	}

	private (PackageReference Reference, bool ExcludeRuntime) GetRuntimeDependencyReference(IValueTable recipeTable, PackageReference dependencyReference)
	{
		if (recipeTable.TryGetValue("Dependencies", out var dependenciesValue))
		{
			var dependenciesTable = dependenciesValue.AsTable()
			if (dependenciesTable.TryGetValue("Runtime", out var runtimeValue))
			{
				var runtimeDependenciesList = runtimeValue.AsList()
				foreach (var dependencyValue in runtimeDependenciesList)
				{
					var dependency = ParseRecipeDependency(dependencyValue)
					if (dependency.Reference == dependencyReference)
						return dependency
				}

				throw new InvalidOperationException("Could not find a Runtime Dependency.")
			}
			else
			{
				throw new InvalidOperationException("Missing Dependencies value in Recipe Table.")
			}
		}
		else
		{
			throw new InvalidOperationException("Missing Dependencies value in Recipe Table.")
		}

	}

	private (PackageReference Reference, bool ExcludeRuntime) ParseRecipeDependency(IValue dependency)
	{
		// A dependency can either be a string or a table with reference key
		if (dependency.IsString())
		{
			return (PackageReference.Parse(dependency.AsString()), false)
		}
		else if (dependency.IsTable())
		{
			var valueTable = dependency.AsTable()

			// Check for optional fields
			bool excludeRuntime = false
			if (valueTable.TryGetValue("ExcludeRuntime", out var excludeRuntimeValue))
			{
				excludeRuntime = excludeRuntimeValue.AsBoolean()
			}

			// Get the require fields
			if (valueTable.TryGetValue("Reference", out var referenceValue))
			{
				if (referenceValue.IsString())
				{
					return (PackageReference.Parse(referenceValue.AsString()), excludeRuntime)
				}
				else
				{
					throw new InvalidOperationException("Recipe dependency Reference must be type String.")
				}
			}
			else
			{
				throw new InvalidOperationException("Recipe dependency table missing required Reference value.")
			}
		}
		else
		{
			throw new InvalidOperationException("Unknown Recipe dependency type.")
		}
	}


	/// <summary>
	/// Find the original reference for the given dependency package name
	/// </summary>
	private PackageReference GetRuntimeDependencyParameterReference(IValueTable parametersTable, string name)
	{
		if (parametersTable.TryGetValue("Dependencies", out var dependenciesValue))
		{
			var dependenciesTable = dependenciesValue.AsTable()
			if (dependenciesTable.TryGetValue("Runtime", out var runtimeValue))
			{
				var runtimeDependenciesTable = runtimeValue.AsTable()
				foreach (var dependencyValue in runtimeDependenciesTable)
				{
					if (dependencyValue.Key == name)
						return ParseParametersDependency(dependencyValue.Value)
				}

				throw new InvalidOperationException("Could not find a Runtime Dependency.")
			}
			else
			{
				throw new InvalidOperationException("Missing Dependencies value in Recipe Table.")
			}
		}
		else
		{
			throw new InvalidOperationException("Missing Dependencies value in Recipe Table.")
		}

	}

	private PackageReference ParseParametersDependency(IValue dependency)
	{
		if (dependency.IsTable())
		{
			var valueTable = dependency.AsTable()

			// Get the require fields
			if (valueTable.TryGetValue("Reference", out var referenceValue))
			{
				if (referenceValue.IsString())
				{
					return PackageReference.Parse(referenceValue.AsString())
				}
				else
				{
					throw new InvalidOperationException("Recipe dependency Reference must be type String.")
				}
			}
			else
			{
				throw new InvalidOperationException("Parameter dependency table missing required Reference value.")
			}
		}
		else
		{
			throw new InvalidOperationException("Unknown Parameters dependency type.")
		}
	}
}
