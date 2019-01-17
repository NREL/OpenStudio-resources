# SDD SIM Files to test SddReverseTranslator

Source: https://sourceforge.net/p/cbecc-com/code/HEAD/tree/trunk/Projects-2016/

```
svn checkout https://svn.code.sf.net/p/cbecc-com/code/trunk cbecc-com-code
cd cbecc-com-code/Projects-2016
```

Used the following Python script to copy only the SDD SIM ones (used for ReverseTranslation)

```python
import glob as gb
import os
import shutil

xml_sim_files = gb.glob("**/*ap.xml", recursive=True)
xml_sim_files = [x for x in xml_sim_files if 'SDD XML Sim Files' in x]

target_folder = '/home/julien/Software/Others/OpenStudio-resources/model/sddtests/'
for xml_sim_file in xml_sim_files:
    dest = os.path.join(target_folder, os.path.basename(xml_sim_file))
    shutil.copyfile(xml_sim_file, dest)
```


