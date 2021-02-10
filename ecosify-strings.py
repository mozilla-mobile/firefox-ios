#!/usr/bin/env python3
import os
import glob 

def _valid_directory(arg, parser):
    if os.path.isdir(arg):
        return arg

    parser.error("Directory does not exist: {}".format(arg))


def ecosify_dir(dir_path):
    for filename in glob.glob(dir_path + '/**/*.strings', recursive=True):
        print(filename)
        if filename.endswith(".strings") and not filename.__contains__("Ecosia"):
            ecosify_translations(filename)
            continue
        else:
            print("File extension not valid {}".format(filename))
            continue


def ecosify_translations(file_path):
    print("Replacing strings in strings file {}".format(file_path))

    with open (file_path, 'r' ) as f:
        try:
            lines = f.readlines()
        except Exception:
            print('cannot open:' + file_path)
            return
    
    newlines = []

    for line in lines:
        parts = line.split('=')
        if len(parts) > 1:
            value = parts[1]
            value = value.replace('Firefox', 'Ecosia')
            value = value.replace('Mozilla', 'Ecosia')
            newlines.append(parts[0] + '=' + value)
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
    parser.add_argument('android_source', type=lambda arg: _valid_directory(arg, parser),
                        help="The android project's src folder")
    args = parser.parse_args()

    ecosify_dir(args.android_source)