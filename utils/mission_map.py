#!/usr/bin/env python3
# This file reads missions data and maps it

import xml.etree.ElementTree as ET
import pygraphviz as pgv
import glob
import os
import argparse

parser = argparse.ArgumentParser(
    description=("Tool to display the relationships between the missions in"
                 " Naikari."))
parser.add_argument(
    "-c", "--ignore-campaigns",
    help="Ignore campaign relationships when creating the graph.",
    action="store_true")
args = parser.parse_args()
ignore_camp = args.ignore_campaigns


i = 0
namdict = {} # Index from name
names = []
dones = []
uniques = [] #
extra_links = [] # List of links given by extra info
meta_nodes = [] # List of meta nodes (useful to control how they're displayed)
camp = [] # Name of the campaigns the missions are in

directory = os.path.split(os.getcwd())
if directory[1] == 'utils':
    prefix = '..'
elif directory[1] == 'naikari':
    prefix = '.'
else:
    print("Failed to detect where you're running this script from\n"
          "Please enter your path manually")

def add_notes(name, parent, base_campaign, campaigns_list):
    notes = parent.find('notes')

    if notes != None:
        campaign = notes.find("campaign")
    else:
        campaign = None

    if campaign == None:
        campTxt = base_campaign
    else:
        campTxt = campaign.text

    campTxt = f'cluster: {campTxt}'
    campaigns_list.append(campTxt)

    if notes == None:
        return

    done_misn = notes.findall('done_misn')
    for dm in done_misn:
        previous = 'Misn: {}'.format(dm.attrib['name'])
        if dm.text == None:
            dm.text = ""
        extra_links.append((previous, name, dm.text))

    done_evt = notes.findall('done_evt')
    for dm in done_evt:
        previous = 'Evt: {}'.format(dm.attrib['name'])
        if dm.text == None:
            dm.text = ""
        extra_links.append((previous, name, dm.text))

    provides = notes.findall('provides')
    for p in provides:
        nextt = p.attrib['name']
        if p.text == None:
            p.text = ""
        extra_links.append((name, nextt, p.text))
        if (not (nextt in meta_nodes)):
            meta_nodes.append((nextt, campTxt))

    requires = notes.findall('requires')
    for r in requires:
        previous = r.attrib['name']
        if r.text == None:
            r.text = ""
        extra_links.append( (previous, name, r.text)  )
        if (not (previous in meta_nodes)):
            # TODO: there will be conflicts between differnent requires
            meta_nodes.append((previous, campTxt))


# Reads all the missions
for missionfile in glob.glob(f'{prefix}/dat/missions/**/*.lua', recursive=True):
    print(missionfile)

    with open(missionfile,'r') as f:
        buf = f.read()
    if buf.find('</mission>') < 0:
        continue
    p = buf.find('--]]')
    if p < 0:
        continue
    xml = buf[5:p]

    tree = ET.ElementTree(ET.fromstring(xml))
    misn = tree.getroot()

    name = 'Misn: {}'.format(misn.attrib['name'])
    names.append(name)
    namdict[name] = i

    avail = misn.find('avail')
    # TODO: I guess findall is needed if there are more than one
    done = avail.find('done')
    dones.append(done)

    flags = misn.find('flags')
    if flags == None:
        uniques.append(False)
    else:
        unique = flags.find('unique')
        if unique == None:
            uniques.append(False)
        else:
            uniques.append(True)

    # Read the notes
    add_notes(name, misn, "Generic Missions", camp)

    i += 1

namdictE = {} # Index from name
namesE = []
uniquesE = []
campE = [] # Name of the campaigns the events are in

i = 0

# Reads all the Events
for eventfile in glob.glob(f'{prefix}/dat/events/**/*.lua', recursive=True):
    print(eventfile)

    with open(eventfile,'r') as f:
        buf = f.read()
    if buf.find('</event>') < 0:
        continue
    p = buf.find('--]]')
    if p < 0:
        continue
    xml = buf[5:p]

    tree = ET.ElementTree(ET.fromstring(xml))
    evt = tree.getroot()

    name = 'Evt: {}'.format(evt.attrib['name'])
    namesE.append(name)
    namdictE[name] = i

    flags = evt.find('flags')
    if flags == None:
        uniquesE.append(False)
    else:
        unique = flags.find('unique')
        if unique == None:
            uniquesE.append(False)
        else:
            uniquesE.append(True)

    # Read the notes
    add_notes(name, evt, "Generic Events", campE)

    i += 1

# Generate graph

G = pgv.AGraph(directed=True)

# Add meta nodes
for node in meta_nodes:
    name = node[0]
    campagn = node[1]
    if (campagn == "cluster: Generic Missions"
            or campagn == "cluster: Generic Events" or ignore_camp):
        G.add_node(name,shape='hexagon',color='red')
    else:
        sub = G.get_subgraph(campagn)
        if sub is None:
            G.add_subgraph(name=campagn,label=campagn)
            sub = G.get_subgraph(campagn)

        sub.add_node(name, shape='hexagon', color='red')


def subgraph_add(name, subN, unique, subN_check, shape):
    if subN == subN_check or ignore_camp:
        if unique:
            G.add_node(name, shape=shape)
        else:
            G.add_node(name, shape=shape, color='grey')
    else:
        sub = G.get_subgraph(subN)
        if sub is None:
            G.add_subgraph(name=subN, label=subN)
            sub = G.get_subgraph(subN)

        if unique:
            sub.add_node(name, shape=shape)
        else:
            sub.add_node(name, shape=shape, color='grey')


# Missions
for i in range(len(names)):
    subgraph_add(names[i], camp[i], uniques[i], "cluster: Generic Missions",
                 'ellipse')

# Same thing for events
for i in range(len(namesE)):
    subgraph_add(namesE[i], campE[i], uniquesE[i], "cluster: Generic Events",
                 'box')


for i in range(len(dones)):
    done = dones[i]
    if done == None:
        continue
    name = names[i]
    G.add_edge(f'Misn: {done.text}', name)

for i in range(len(extra_links)):
    link = extra_links[i]
    G.add_edge(link[0], link[1], label=link[2], color='red')

#G.graph_attr['rank']='same'
G.layout(prog='dot')
#G.layout(prog='neato')
G.draw('missions.svg')
