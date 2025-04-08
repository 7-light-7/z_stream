# z_stream
Wayland-Compositor based on wlroots


## Why do this

I want to create my own standalone tiling WM to avoid some of the design patterns that I don't like as much in other available options. My goal is for it to function as an entire DE, for power users, i.e. lightweight. This project will be heavily influenced by the river project, as I plan to write in Zig. I will be taking notes from hyprland and Sway as well.

## Features I hope to inlcude

- Better install process
  - No init start with a generated config file, step through install and set all key packages there
  - Why? Standalone design, it should be able to operate regardless of any other DE
- Zoom out of all workspaces
- Reduce dependence on num keys
- More hotkeying of moving windows around
- Multiple monitors as one workspace
- Screen lock and suspend out of the box
- Ultra power save
  - based on the old galaxy phones, this ruled
  - turn of all power hungry features, and extra services
  - Black and white only
  - No animations
  - Why? Push old laptops to their performance limit. Ultimately as a developer, I am most concerned about being able to write code without issue.
- Maybe attempt gaming support but this is a low priority for me.


