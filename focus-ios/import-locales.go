// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/st3fan/xliff"
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

func writeStrings(file xliff.File, path string, skipTransUnits []string, allowIncomplete bool) error {
	w, err := os.Create(path)
	if err != nil {
		return err
	}
	defer w.Close()

	for _, transUnit := range file.Body.TransUnits {
		if shouldSkipTransUnit(transUnit, skipTransUnits) {
			continue
		}
		// If we allow incomplete strings, then do not write this
		// string out at all. The app will default to the english base
		// string if the string is not present for a locale.
		if allowIncomplete && transUnit.Target == "" {
			continue
		}
		if transUnit.Note != "" {
			fmt.Fprintf(w, "/* %s */\n", transUnit.Note)
		} else {
			fmt.Fprintf(w, "/* (No Comment) */\n")
		}
		fmt.Fprintf(w, "\"%s\" = \"%s\";\n\n", transUnit.ID, escapeString(transUnit.Target))
	}

	return nil
}

func removeMissingTransUnitTargetErrors(errors []xliff.ValidationError) []xliff.ValidationError {
	var result []xliff.ValidationError
	for _, error := range errors {
		if error.Code != xliff.MissingTransUnitTarget {
			result = append(result, error)
		}
	}
	return result
}

func main() {
	var allowIncomplete = flag.Bool("allowIncomplete", false, "Allow incomplete locales to be imported")

	flag.Parse()

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
	for _, path := range flag.Args() {
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

		if !doc.IsComplete() && !*allowIncomplete {
			fmt.Printf("Skipping: %s: not completely localized\n", path)
			continue Loop
		}

		// Validate the document. If we allow incomplete locales then
		// we ignore MissingTransUnitTarget errors. Other errors will
		// will result in a complete rejection of the file.

		errors := doc.Validate()
		if len(errors) != 0 {
			if *allowIncomplete {
				errors = removeMissingTransUnitTargetErrors(errors)
			}
			if len(errors) != 0 {
				for _, err := range errors {
					fmt.Printf("Skipping: %s: because of validation error: %s\n", path, err)
				}
				continue Loop
			}
		}

		// Everything is good to go, actually import strings
		for _, file := range doc.Files {
			if unlocalizedDestination, ok := fileMappings[file.Original]; ok {
				destination := localizedDestination(unlocalizedDestination, file.TargetLanguage)
				if err := writeStrings(file, destination, skipTransUnits, *allowIncomplete); err != nil {
					fmt.Printf("Error: Failed to write strings for %s: %v\n", path, err)
				}
			}
		}
	}
}
