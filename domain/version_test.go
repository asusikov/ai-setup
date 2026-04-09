package domain

import (
	"regexp"
	"testing"
)

func TestGetVersion(t *testing.T) {
	tests := []struct {
		name    string
		check   func(string) bool
		message string
	}{
		{
			name:    "returns non-empty string",
			check:   func(v string) bool { return v != "" },
			message: "GetVersion() returned empty string",
		},
		{
			name:    "equals version variable",
			check:   func(v string) bool { return v == version },
			message: "GetVersion() does not match version variable",
		},
		{
			name:    "follows semver format",
			check:   func(v string) bool { return regexp.MustCompile(`^\d+\.\d+\.\d+$`).MatchString(v) },
			message: "GetVersion() does not match semver format X.Y.Z",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := GetVersion()
			if !tt.check(got) {
				t.Errorf("%s, got %q", tt.message, got)
			}
		})
	}
}
