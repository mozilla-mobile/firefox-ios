#!/usr/bin/env python3
import os
import glob
import re


def _valid_directory(arg, parser):
    if os.path.isdir(arg):
        return arg

    parser.error("Directory does not exist: {}".format(arg))


def ecosify_dir(dir_path):
    for filename in glob.glob(dir_path + '/**/*.strings', recursive=True):
        print(filename)
        isStringsFile = filename.endswith(".strings")
        isEcosiaFile = filename.__contains__("Ecosia")
        if isStringsFile and not isEcosiaFile:
            ecosify_translations(filename)
            continue
        else:
            print("File extension not valid {}".format(filename))
            continue


def ecosify_translations(file_path):
    print("Replacing strings in strings file {}".format(file_path))

    with open(file_path, 'r') as f:
        try:
            lines = f.readlines()
        except Exception:
            print('cannot open:' + file_path)
            return

    newlines = []
    brandnames = [
        'firefoksa',
        'firefoxen',
        'firefoxu',
        'firefoxe',
        'firefoxban',
        'firefoksie',
        'firefox',
        'mozilla'
        ]

    for line in lines:
        parts = line.split('=')
        if len(parts) > 1:
            value = parts[1]

            for name in brandnames:
                value = re.sub(name, 'Ecosia', value, flags=re.IGNORECASE)

            newlines.append(parts[0] + '=' + value)
        elif line.strip().endswith(';'):
            # some translation values break lines and are ophaned
            # we need to replace values there too
            for name in brandnames:
                line = re.sub(name, 'Ecosia', line, flags=re.IGNORECASE)
            newlines.append(line)
        else:
            newlines.append(line)

    # writing to file
    with open(file_path, 'w') as f:
        f.writelines(newlines)
    f.close()


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Replace Firefox and Mozilla strings with Ecosia",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('ios_source',
                        type=lambda arg: _valid_directory(arg, parser),
                        help="The ios project's src folder")
    args = parser.parse_args()

    ecosify_dir(args.ios_source)
