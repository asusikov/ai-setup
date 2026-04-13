package cmd

import (
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "ai-setup",
	Short: "TUI app to operate with GitLab",
}

func Execute() error {
	return rootCmd.Execute()
}
