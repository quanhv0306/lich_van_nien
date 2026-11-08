import os
import sys
from PIL import Image

def process_icon(source_path, project_root):
    img = Image.open(source_path).convert("RGBA")
    w, h = img.size
    
    # Crop to 1:1 square if not already
    min_dim = min(w, h)
    left = (w - min_dim) // 2
    top = (h - min_dim) // 2
    img = img.crop((left, top, left + min_dim, top + min_dim))
    img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    print(f"Loaded master icon: {source_path} (1024x1024)")

    # 1. Web icons
    web_dir = os.path.join(project_root, "web")
    web_icons_dir = os.path.join(web_dir, "icons")
    os.makedirs(web_icons_dir, exist_ok=True)
    
    # Favicon
    img.resize((48, 48), Image.Resampling.LANCZOS).save(os.path.join(web_dir, "favicon.png"), "PNG")
    print("Generated web/favicon.png (48x48)")
    
    # Web manifest icons
    img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")
    img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")
    print("Generated web/icons/Icon-192.png & Icon-512.png")
    
    # Maskable icons (add 10% padding so safe zone fits round icons)
    for sz in [192, 512]:
        maskable = Image.new("RGBA", (sz, sz), (166, 28, 28, 255)) # Imperial red background #A61C1C
        inner_sz = int(sz * 0.8)
        inner = img.resize((inner_sz, inner_sz), Image.Resampling.LANCZOS)
        offset = (sz - inner_sz) // 2
        maskable.paste(inner, (offset, offset), inner)
        maskable.save(os.path.join(web_icons_dir, f"Icon-maskable-{sz}.png"), "PNG")
    print("Generated web maskable icons (192 & 512)")

    # 2. Android launcher icons
    android_res = os.path.join(project_root, "android", "app", "src", "main", "res")
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, sz in android_sizes.items():
        target_dir = os.path.join(android_res, folder)
        os.makedirs(target_dir, exist_ok=True)
        img.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(target_dir, "ic_launcher.png"), "PNG")
    print("Generated Android mipmap launcher icons")

    # 3. iOS app icons
    ios_dir = os.path.join(project_root, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if os.path.exists(ios_dir):
        ios_files = {
            "Icon-App-20x20@1x.png": 20,
            "Icon-App-20x20@2x.png": 40,
            "Icon-App-20x20@3x.png": 60,
            "Icon-App-29x29@1x.png": 29,
            "Icon-App-29x29@2x.png": 58,
            "Icon-App-29x29@3x.png": 87,
            "Icon-App-40x40@1x.png": 40,
            "Icon-App-40x40@2x.png": 80,
            "Icon-App-40x40@3x.png": 120,
            "Icon-App-60x60@2x.png": 120,
            "Icon-App-60x60@3x.png": 180,
            "Icon-App-76x76@1x.png": 76,
            "Icon-App-76x76@2x.png": 152,
            "Icon-App-83.5x83.5@2x.png": 167,
            "Icon-App-1024x1024@1x.png": 1024,
        }
        for fname, sz in ios_files.items():
            img.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(ios_dir, fname), "PNG")
        print("Generated iOS AppIcon set")

    # 4. macOS app icons
    macos_dir = os.path.join(project_root, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    if os.path.exists(macos_dir):
        macos_files = {
            "app_icon_16.png": 16,
            "app_icon_32.png": 32,
            "app_icon_64.png": 64,
            "app_icon_128.png": 128,
            "app_icon_256.png": 256,
            "app_icon_512.png": 512,
            "app_icon_1024.png": 1024,
        }
        for fname, sz in macos_files.items():
            img.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(macos_dir, fname), "PNG")
        print("Generated macOS AppIcon set")

    # 5. Windows app icon (.ico)
    windows_res = os.path.join(project_root, "windows", "runner", "resources")
    if os.path.exists(windows_res):
        ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        img.save(os.path.join(windows_res, "app_icon.ico"), format="ICO", sizes=ico_sizes)
        print("Generated Windows app_icon.ico")

    # Also save master icon in assets/images/
    assets_img_dir = os.path.join(project_root, "assets", "images")
    os.makedirs(assets_img_dir, exist_ok=True)
    img.save(os.path.join(assets_img_dir, "app_icon_master.png"), "PNG")
    print(f"Saved master icon to {os.path.join(assets_img_dir, 'app_icon_master.png')}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generate_app_icons.py <source_image_path>")
        sys.exit(1)
    
    src = sys.argv[1]
    root = r"H:\Codes\lich_van_nien"
    process_icon(src, root)
