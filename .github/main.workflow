workflow "Basic tests" {
  on = "push"
  resolves = ["SpellCheck", "ShellCheck"]
}

action "ShellCheck" {
  uses = "./.github/shellcheck/"
}

action "SpellCheck" {
  uses = "./.github/spellcheck/"
}
