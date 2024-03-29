﻿// <copyright file="InitializeDefaultsTask.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup" for Soup, SoupTask
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "mwasplund|Soup.Build.Utils:./ListExtensions" for ListExtensions
import "mwasplund|Soup.Build.Utils:./MapExtensions" for MapExtensions

/// <summary>
/// The initialize defaults task that knows how to initialize default values for a given host environment
/// </summary>
class InitializeDefaultsTask is SoupTask {
	/// <summary>
	/// Get the run before list
	/// </summary>
	static runBefore { [
		"BuildTask",
	] }

	/// <summary>
	/// Get the run after list
	/// </summary>
	static runAfter { [] }

	/// <summary>
	/// The Core Execute task
	/// </summary>
	static evaluate() {
		var globalState = Soup.globalState
		var activeState = Soup.activeState

		var context = globalState["Context"]
		var parameters = globalState["Parameters"]

		var build = MapExtensions.EnsureTable(activeState, "Build")

		var hostPlatform = context["HostPlatform"]

		var architecture = "AnyCPU"
		var compiler = "Roslyn"
		var flavor = "Debug"

		if (parameters.containsKey("Architecture")) {
			architecture = parameters["Architecture"]
		}

		if (parameters.containsKey("Flavor")) {
			flavor = parameters["Flavor"]
		}

		// Save the internal parameters
		build["Architecture"] = architecture
		build["Compiler"] = compiler
		build["Flavor"] = flavor
	}
}
