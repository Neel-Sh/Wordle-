#!/usr/bin/env python3
"""Build Encore's offline library from the official SCOWL 2020.12.07 release.

Usage: python3 script/build_word_library.py /path/to/scowl-2020.12.07
Source: https://downloads.sourceforge.net/wordlist/scowl-2020.12.07.tar.gz
"""
from pathlib import Path
import hashlib
import json
import re
import sys

source = Path(sys.argv[1])
destination = Path(__file__).resolve().parents[1] / 'Wordle' / 'Resources'
destination.mkdir(parents=True, exist_ok=True)
# Exact terms and inflections; do not accidentally remove unrelated words.
excluded = set('''arse arses arsehole arseholes asshole assholes bastard bastards
bitch bitches bitchy bollock bollocks boner boners bullshit cocks cunt cunts
dick dicks dildo dildos douche douches fag fags faggot faggots fuck fucked
fucker fuckers fucking fucks goddamn handjob handjobs jizz kike kikes nigger
niggers nigga niggas piss pissed pisses pissing porn porno pornos rape raped
rapes raping rapist rapists retard retards retarded shit shits shitty slut sluts
slutty spic spics tit tits titties twat twats wank wanks wanker wankers whore
whores whoring chink chinks coon coons cum cums cumshot semen sperm fellate
fellatio blowjob blowjobs'''.upper().split())

def word_pool(level):
    words = set()
    for path in (source / 'final').iterdir():
        match = re.fullmatch(r'(english|american)-words\.(\d+)', path.name)
        if match and int(match[2]) <= level:
            words.update(word.upper() for word in path.read_text(encoding='latin1').splitlines()
                         if re.fullmatch(r'[a-z]{4,7}', word))
    return words

configuration = {'easy': (4, 40), 'medium': (5, 50), 'hard': (6, 50), 'expert': (7, 55)}
answers = {name: sorted(word for word in word_pool(level) - excluded if len(word) == length)
           for name, (length, level) in configuration.items()}
accepted = sorted(word_pool(70) - excluded)
assert all(len(words) > 500 for words in answers.values())
assert set().union(*map(set, answers.values())) <= set(accepted)
(destination / 'answers.json').write_text(json.dumps(answers, indent=2) + '\n')
(destination / 'accepted.txt').write_text('\n'.join(accepted) + '\n')
license_text = (source / 'Copyright').read_text(encoding='latin1')
(destination / 'WordListLicense.txt').write_text(license_text)
manifest = {
    'source': 'SCOWL 2020.12.07',
    'source_url': 'https://downloads.sourceforge.net/wordlist/scowl-2020.12.07.tar.gz',
    'answer_counts': {key: len(value) for key, value in answers.items()},
    'accepted_count': len(accepted),
    'answer_rules': 'Lowercase American and general English, ASCII letters only, selected sensitive terms excluded.',
    'levels': {key: level for key, (_, level) in configuration.items()},
    'sha256': {name: hashlib.sha256((destination / name).read_bytes()).hexdigest()
               for name in ('answers.json', 'accepted.txt', 'WordListLicense.txt')}
}
(destination / 'WordLibraryManifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps(manifest, indent=2))
