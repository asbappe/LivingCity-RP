"""Living City map ingestion: the parts behind _dev/tools/map_ingest.py, one file each (each under 20 KB).

    vmf.py       the shared reader: entities (keys, outputs), brushes and faces as arrays, displacements, hidden flags
    sky.py       the 3D skybox room round the sky_camera
    geom.py      rays and true slices through the solid brushes and displaced ground
    common.py    distributions, model kinds, angles, model sizes
    census.py    what is in the map, counted
    sections.py  streets, rooms, stairs and doorways at the AI nodes; cut pictures
    channels.py  canal-style channel profiles
    props.py     how props are placed
    logic.py     how the map is wired
    craft.py     texture and brush craft (with surfaces.py: walls, glass, slopes, displacements;
                 and light.py: light recipes, decals and overlays)
    views.py     candidate pictures scored by their pixels, the best drawn with map_view.render
    report.py    sentences from the measurements and the draft pictures.json
    aggregate.py statistics across every ingested map
"""
