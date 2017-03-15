#! /usr/bin/env python

import itertools as it
import numpy as np
import scipy as sp
from scipy import optimize

from Levenshtein import jaro

def sim_eval(a, b, padding, offset):
    n = len(a) + 2*padding
    ## print('Comparing ({}:{}) ({}|{}|{}) : ({})'.format(
    ##     padding,
    ##     offset,
    ##     b[offset:offset + padding],
    ##     a,
    ##     b[offset + n - padding:offset + n],
    ##     b[offset:offset+n]))

    return jaro(
            '{}{}{}'.format(
                b[offset:offset + padding],
                a,
                b[offset + n - padding:offset + n]),
            b[offset:offset+n])

def sim(a, b):
    an = len(a)
    bn = len(b)

    if an > bn:
        a, b = b, a
        an, bn = bn, an

    result = max(
            it.chain.from_iterable(
                (
                    sim_eval(a, b, padding, offset)
                    for offset in range(bn - an - 2*padding + 1)
                )
                for padding in range((bn - an)//2 + 1)
            ))

    weight = 1.0/(2 + bn - an)
    return (1.0 - weight)*result + weight*jaro(a, b)

def sim2(list1, list2):
    cost_matrix = np.array(tuple(
        tuple(1.0 - sim(r, c) for c in list2)
        for r in list1))

    assign1, assign2 = (
            optimize.linear_sum_assignment(cost_matrix))

    return (np.mean(1.0 - cost_matrix[assign1, assign2]), assign1, assign2)

MODE_OPEN = 0
MODE_TEXT = 1
MODE_NUMERIC = 2
def parse(x):
    mode = MODE_OPEN
    result = []
    current = []

    for c in x:
        if mode == MODE_OPEN:
            if (('a' <= c and c <= 'z') or
                    ('A' <= c and c <= 'Z')):
                mode = MODE_TEXT
                current.append(c.lower())

            if ('0' <= c and c <= '9'):
                mode = MODE_NUMERIC
                current.append(c.lower())

        elif mode == MODE_TEXT:
            if (('a' <= c and c <= 'z') or
                    ('A' <= c and c <= 'Z')):
                current.append(c.lower())
            elif ('0' <= c and c <= '9'):
                mode = MODE_NUMERIC
                result.append(''.join(current))
                current = [c]
            else:
                if current:
                    result.append(''.join(current))
                    current = []
                mode = MODE_OPEN

        elif mode == MODE_NUMERIC:
            if ('0' <= c and c <= '9'):
                current.append(c)
            elif (('a' <= c and c <= 'z') or
                    ('A' <= c and c <= 'Z')):
                mode = MODE_TEXT
                result.append(''.join(current))
                current = [c.lower()]
            else:
                if current:
                    result.append(''.join(current))
                    current = []
                mode = MODE_OPEN

    if current:
        result.append(''.join(current))

    return [ x for x in result if x ]

if __name__ == '__main__':
    from sys import argv
    file1 = argv[1]
    file2 = argv[2]

    list1 = [line[:-1] for line in open(file1)]
    list2 = [line[:-1] for line in open(file2)]

    # cost_matrix = np.array(tuple(
    #     tuple(1.0 - sim(r, c) for c in list2)
    #     for r in list1))

    cost_matrix = np.array(tuple(
        tuple(1.0 - sim2(r, c)[0] for c in list2)
        for r in list1))

    assign1, assign2 = (
            optimize.linear_sum_assignment(cost_matrix))

    entries = sorted(
            ((list1[a1], list2[a2], 1.0 - cost_matrix[a1, a2])
            for (a1, a2) in zip(assign1, assign2)),
            key=(lambda x: (-x[2], x[0], x[1])))

    if not False:
        for e in entries:
            a, b = e[:2]
            ap = parse(a)
            bp = parse(b)
            score, Aa, Ab = sim2(ap, bp)

            print(a)
            print(b)
            print('=======')
            print(ap)
            print(bp)
            print('=======')
            print([ap[i] for i in Aa])
            print([bp[i] for i in Ab])
            print(score)
            print('(%20s|%20s) : (%12.4f)' % e)
            print('')

    print('\n'.join(
        ('(%20s|%20s) : (%12.4f)' % tup)
        for tup in entries))

    print('Overall Confidence: {}'.format(
        np.mean(1.0 - cost_matrix[assign1, assign2])))
