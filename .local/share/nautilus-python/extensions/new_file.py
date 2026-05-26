import subprocess
import urllib.parse
from gi.repository import Nautilus, GObject

class NewFileMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def get_background_items(self, current_folder):
        item = Nautilus.MenuItem(
            name='NewFileExtension::new_file',
            label='New File...',
            tip='Create a new file in this folder'
        )
        item.connect('activate', self._new_file, current_folder)
        return [item]

    def _new_file(self, menu, folder):
        folder_path = urllib.parse.unquote(folder.get_uri()[7:])
        proc = subprocess.run(
            ['zenity', '--entry', '--title=New File',
             '--text=Enter filename (with extension):', '--width=320'],
            capture_output=True, text=True
        )
        name = proc.stdout.strip()
        if name:
            open(f'{folder_path}/{name}', 'a').close()
