-- Installation:
-- # Install Metals (Scala language server) via Coursier
-- brew install coursier/formulas/coursier
-- cs install metals
--
-- Make sure ~/.local/share/coursier/bin (or wherever `cs install` puts
-- binaries) is in the PATH
-- export PATH="$PATH:$HOME/.local/share/coursier/bin"
return {
    cmd = { "metals" },                                                             -- Command to start the language server
    filetypes = { "scala", "sbt" },                                                 -- File types that this server will handle
    root_markers = { "build.sbt", "build.sc", "build.gradle", "pom.xml", ".git" },  -- Markers to identify the root of the project
    settings = {
        metals = {
            showImplicitArguments = true,
            showImplicitConversionsAndClasses = true,
            showInferredType = true,
            superMethodLensesEnabled = true,
            excludedPackages = {
                "akka.actor.typed.javadsl",
                "com.github.swagger.akka.javadsl",
            },
        },
    },
    init_options = {
        statusBarProvider = "on",
    },
    single_file_support = true,
}
