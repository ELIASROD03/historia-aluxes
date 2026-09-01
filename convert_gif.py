from PIL import Image
import sys

def processImage(infile):
    try:
        im = Image.open(infile)
    except IOError:
        print("Cant load", infile)
        sys.exit(1)

    frames = []
    try:
        while True:
            # Append a copy of the current frame
            frames.append(im.copy().convert('RGBA'))
            im.seek(len(frames)) # next frame
    except EOFError:
        pass # end of sequence

    if not frames:
        print("No frames found.")
        sys.exit(1)

    width, height = frames[0].size
    spritesheet_width = width * len(frames)
    spritesheet_height = height

    spritesheet = Image.new("RGBA", (spritesheet_width, spritesheet_height))

    for i, frame in enumerate(frames):
        spritesheet.paste(frame, (i * width, 0))

    outfile = infile.replace('.gif', '_spritesheet.png')
    spritesheet.save(outfile)
    print(f"Saved {len(frames)} frames to {outfile}")

if __name__ == "__main__":
    import os
    gif_path = r"C:\Users\elias\OneDrive\Documentos\los-aluxes-que-cambiaron-la-historia\Images\Personajes\Npc_level1\hombre_canoa.gif"
    if os.path.exists(gif_path):
        processImage(gif_path)
    else:
        print(f"File not found: {gif_path}")
