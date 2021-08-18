# SPDX-License-Identifier: GPL-3.0-or-later

import os
import math

from .material import Material
from .object import Object
from .texture import loadTexture


def mtl_getopt(args, arg_spec):
    results = {}

    i = 0
    while i < len(args):
        matched = False
        if args[i].startswith('-'):
            for name, count in arg_spec.items(): 
                if args[i][1:] == name:
                    results[name] = tuple(args[i+1:i+count+1])
                    i += count
                    matched = True
        if not matched:
            break
        i += 1

    return (results, tuple(args[i:]))


def parse_mtl(path):
    f = open(path)

    materials = {}
    cur_material = None

    for l in f:
        l = l.split()
        if not l or l[0].startswith('#'):
            continue

        if l[0] == 'newmtl':
            m = Material()
            materials[l[1]] = m
            cur_material = m
        # Ambient
        elif l[0] == 'Ka':
            cur_material.Ka = tuple(float(i) for i in l[1:4])
        # Diffuse
        elif l[0] == 'Kd':
            cur_material.Kd = tuple(float(i) for i in l[1:4])
        # Specular
        elif l[0] == 'Ks':
            cur_material.Ks = tuple(float(i) for i in l[1:4])
        elif l[0] == 'Ns':
            cur_material.Ns = float(l[1])
        elif l[0] == 'Ni':
            cur_material.Ni = float(l[1])
        elif l[0] == 'd':
            cur_material.d = float(l[1])
        elif l[0] == 'map_Kd':
            # XXX handle s
            opts, rest = mtl_getopt(l[1:], {'s': 3})
            map_Kd = ' '.join(rest)
            cur_material.map_Kd = loadTexture(os.path.dirname(path) + '/' + map_Kd)
        elif l[0] == 'map_Bump':
            # XXX handle s
            opts, rest = mtl_getopt(l[1:], {'s': 3, 'bm': 1})
            if 'bm' in opts:
               cur_material.bm = float(opts['bm'][0])
            else:
               cur_material.bm = 1.0
            map_Bump = ' '.join(rest)
            cur_material.map_Bump = loadTexture(os.path.dirname(path) + '/' + map_Bump)
        # Illumination mode
        elif l[0] == 'illum':
            pass
        else:
            print(f"Ignoring {l[0]}")

    return materials


def parse_obj(path):
    f = open(path)

    objects = {}
    cur_object = None
    mtls = None

    v_list = []
    vt_list = []
    vn_list = []

    for l in f:
        l = l.split()
        if not l or l[0].startswith('#'):
            continue

        # Load materials from file
        if l[0] == 'mtllib':
            mtls = parse_mtl(os.path.dirname(path) + '/' + l[1])
        # Use material
        elif l[0] == 'usemtl':
            cur_object.mtl_list.append([mtls[l[1]], len(cur_object.vertices) // 8, 0])
        # Smoothing
        elif l[0] == 's':
            pass
        # Face
        elif l[0] == 'f':
            for i in l[1:4]:
                v, vt, vn = (int(j or 0) for j in i.split('/'))
                cur_object.vertices.extend(v_list[v - 1])
                if (vt == 0):
                    cur_object.vertices.extend((0, 0))
                else:
                    cur_object.vertices.extend(vt_list[vt - 1])
                cur_object.vertices.extend(vn_list[vn - 1])
            cur_object.mtl_list[-1][2] += 3
        # Vertex
        elif l[0] == 'v':
            v_list.append(tuple(float(i) for i in l[1:4]))
        # Texture vertex
        elif l[0] == 'vt':
            vt_list.append(tuple(float(i) for i in l[1:3]))
        # Vertex normal
        elif l[0] == 'vn':
            vn_list.append(tuple(float(i) for i in l[1:4]))
        # Object
        elif l[0] == 'o':
            cur_object = Object()
            objects[l[1]] = cur_object
        # Ignore lines
        elif l[0] == 'l':
            pass
        else:
            print(f"Ignoring {l[0]}")

    return objects
