package main

import (
	"fmt"
	"github.com/st3fan/xliff"
	"os"
	"path/filepath"
	"strings"
)

func localizedDestination(dest string, language string) string {
	if language == "tl" {
		language = "fil"
	}
	dir, file := filepath.Split(dest)
	return filepath.Join(dir, fmt.Sprintf("%s.lproj", language), file)
}

func shouldSkipTransUnit(transUnit xliff.TransUnit, skipTransUnits []string) bool {
	for _, s := range skipTransUnits {
		if s == transUnit.ID {
			return true
		}
	}
	return false
}

func escapeString(s string) string {
	return strings.Replace(s, `"`, `\"`, -1)
}

func writeStrings(file xliff.File, path string, skipTransUnits []string) error {
	w, err := os.Create(path)
	if err != nil {
		return err
	}
	defer w.Close()

	for _, transUnit := range file.Body.TransUnits {
		if shouldSkipTransUnit(transUnit, skipTransUnits) {
			continue
		}
		if transUnit.Note != "" {
			fmt.Fprintf(w, "/* %s */\n", transUnit.Note)
		} else {
			fmt.Fprintf(w, "/* (No Commment) */\n")
		}
		fmt.Fprintf(w, "\"%s\" = \"%s\";\n\n", transUnit.ID, escapeString(transUnit.Target))
	}

	return nil
}

func main() {
	fileMappings := map[string]string{
		"Blockzilla/Info.plist":                   "Blockzilla/InfoPlist.strings",
		"Blockzilla/en.lproj/Localizable.strings": "Blockzilla/Localizable.strings",
	}

	skipTransUnits := []string{
		"CFBundleDisplayName",
		"CFBundleName",
		"CFBundleShortVersionString",
	}

Loop:
	for _, path := range os.Args[1:] {
		fmt.Println("Processing ", path)

		doc, err := xliff.FromFile(path)
		if err != nil {
			fmt.Printf("Skipping: %s: %v\n", path, err)
			continue Loop
		}

		// Dry run to make sure this locale is part of the project already
		for _, file := range doc.Files {
			if unlocalizedDestination, ok := fileMappings[file.Original]; ok {
				destination := localizedDestination(unlocalizedDestination, file.TargetLanguage)
				if _, err := os.Stat(destination); os.IsNotExist(err) {
					fmt.Printf("Skipping: %s: not imported into the project first\n", path)
					continue Loop
				}
			}
		}

		if !doc.IsComplete() {
			fmt.Printf("Skipping: %s: not completely localized\n", path)
			continue Loop
		}

		errors := doc.Validate()
		if len(errors) != 0 {
			for _, err := range errors {
				fmt.Printf("Skipping: %s: because of validation error: %s\n", path, err)
			}
			continue Loop
		}

		// Everything is good to go, actually import strings
		for _, file := range doc.Files {
			if unlocalizedDestination, ok := fileMappings[file.Original]; ok {
				destination := localizedDestination(unlocalizedDestination, file.TargetLanguage)
				if err := writeStrings(file, destination, skipTransUnits); err != nil {
					fmt.Printf("Error: Failed to write strings for %s: %v\n", path, err)
				}
			}
		}
	}
}
