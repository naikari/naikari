#!/usr/bin/env python3

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

"""
Bio outfit template exporter. Takes a .xml.template file and a
corresponding .xml.template.json file and uses them to fill up all
levels of a given outfit.

Each .xml.template file is the regular XML file, but with portions that
are to be replaced programmatically designated by str.format() tags,
e.g. "{spam}" and "{egg}". The JSON file then contains content that
might look something like this:

    {
        "stages": 6,
        "tags": {
            "spam": {
                "min": 100,
                "max": 600
            },
            "egg": {
                "text": {
                    "default": "Spam, spam, spam, spam."
                    "stage": {
                        "1": "Have you got anything without spam in it?",
                        "3": "I don't like spam!",
                        "X": "Wonderful spam, lovely spam!"
                    }
                }
            }
        }
    }
"""


__version__ = "1.0"


import argparse
import json
import math
import os


parser = argparse.ArgumentParser()
parser.add_argument(
    "-t", "--template",
    help=("Which template to build. Must have a corresponding file with the"
          " same name plus '.json' (e.g. 'spam.xml.template' must have a"
          " corresponding 'spam.xml.template.json')."))
args = parser.parse_args()


def export_stage(basefname, template_text, stages, tags, cur_stage):
    assert stages > 0

    if cur_stage + 1 >= stages:
        print_stage = "X"
    else:
        print_stage = str(cur_stage + 1)

    cur_tags = {}
    cur_tags["stage"] = print_stage
    for tag, data in tags.items():
        if "text" in data:
            tdata = data["text"]
            default = tdata.get("default", "")
            stage_ovr = tdata.get("stage", {})
            if print_stage in stage_ovr:
                cur_tags[tag] = stage_ovr[print_stage]
            else:
                cur_tags[tag] = default
        elif "min" in data and "max" in data:
            minv = data["min"]
            maxv = data["max"]
            if cur_stage >= stages - 1:
                cur_tags[tag] = maxv
            elif cur_stage <= 0:
                cur_tags[tag] = minv
            else:
                diff = maxv - minv
                v = minv + diff*cur_stage/(stages-1)
                if diff / (stages-1) >= 2:
                    v = math.floor(v)
                cur_tags[tag] = v

    xml_out = template_text.format(**cur_tags)
    fname = f"{basefname}_stage_{print_stage.casefold()}.xml"
    with open(fname, "w") as f:
        f.write(xml_out)
    print(f"Successfully wrote to {fname}.")


def main():
    if args.template:
        tfname = args.template
        with open(tfname, "r") as f:
            template_text = f.read()
        with open(tfname + ".json", "r") as f:
            template_meta = json.load(f)

        basename = tfname.replace(".xml.template", "")

        stages = template_meta.get("stages", 1)
        tags = template_meta.get("tags", {})

        for i in range(stages):
            export_stage(basename, template_text, stages, tags, i)

        print("Finished exporting successfully.")
    else:
        print("Please specify the -t argument indicating the template file.")


if __name__ == "__main__":
    main()
