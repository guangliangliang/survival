#!/usr/bin/env python3
"""Normalize enemy 4-frame sprite sheets for the Godot enemy animator.

The runtime in scripts/systems/Enemy.gd reads sheets as:
    frame_width = (texture_width - 20 * 3) / 4
    frame_x = frame_index * (frame_width + 20)

Most AI sheets are plain 4-way splits with no explicit gap. This tool crops the
four source poses, keeps one shared scale, bottom-aligns them, and writes a
sheet that matches the runtime layout while preserving the original dimensions.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
from PIL import Image, ImageDraw


FRAME_COUNT = 4
FRAME_GAP = 20
ALPHA_THRESHOLD = 8
INNER_PADDING = 24
TOP_PADDING = 12
BOTTOM_PADDING = 12
EDGE_BAND_RATIO = 0.08
EDGE_FRAGMENT_MAX_RATIO = 0.35
MIN_FRAGMENT_AREA = 120
FILTER_EDGE_FRAGMENTS = False

DEFAULT_TARGETS = (
    "enemy_wolf_attack_right_4.png",
    "enemy_alpha_wolf_attack_right_4.png",
    "enemy_boar_attack_right_4.png",
    "enemy_thorn_porcupine_attack_right_4.png",
    "enemy_forest_beast_attack_right_4.png",
    "enemy_bandit_attack_right_4.png",
    "enemy_musketeer_bandit_attack_right_4.png",
    "enemy_cult_wizard_attack_right_4.png",
    "enemy_elite_bandit_attack_right_4.png",
    "enemy_bandit_chief_attack_right_4.png",
    "enemy_alpha_wolf_walk_right_4.png",
    "enemy_forest_beast_walk_right_4.png",
    "enemy_bandit_walk_right_4.png",
    "enemy_cult_wizard_walk_right_4.png",
    "enemy_elite_bandit_walk_right_4.png",
    "enemy_bandit_chief_walk_right_4.png",
)


@dataclass(frozen=True)
class Bounds:
    left: int
    top: int
    right: int
    bottom: int

    @property
    def width(self) -> int:
        return self.right - self.left

    @property
    def height(self) -> int:
        return self.bottom - self.top

    @property
    def center_x(self) -> float:
        return (self.left + self.right - 1) / 2.0

    @property
    def baseline(self) -> int:
        return self.bottom - 1


@dataclass
class FrameReport:
    index: int
    bounds: Bounds | None
    left_margin: int | None = None
    right_margin: int | None = None


@dataclass
class SheetReport:
    path: Path
    size: tuple[int, int]
    frame_width: int
    source_cell_width: int
    before_frames: list[FrameReport]
    after_frames: list[FrameReport]
    scale: float
    gaps_clean_before: bool
    gaps_clean_after: bool
    output_path: Path | None
    filtered_fragments: int = 0


@dataclass(frozen=True)
class Component:
    label: int
    bounds: Bounds
    area: int

    @property
    def center_x(self) -> float:
        return self.bounds.center_x


def _threshold_bbox(image: Image.Image, threshold: int = ALPHA_THRESHOLD) -> Bounds | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        return None
    return Bounds(*bbox)


def _frame_width_for_runtime(width: int, frames: int, gap: int) -> int:
    usable_width = width - gap * (frames - 1)
    if usable_width <= 0 or usable_width % frames != 0:
        raise ValueError(
            f"texture width {width} is not compatible with {frames} frames and {gap}px gaps"
        )
    return usable_width // frames


def _source_cell_width(width: int, frames: int) -> int:
    if width % frames != 0:
        raise ValueError(f"texture width {width} cannot be split into {frames} equal source cells")
    return width // frames


def _collect_frame_reports(
    image: Image.Image,
    starts: Iterable[int],
    frame_width: int,
    threshold: int = ALPHA_THRESHOLD,
) -> list[FrameReport]:
    reports: list[FrameReport] = []
    for index, x0 in enumerate(starts):
        region = image.crop((x0, 0, x0 + frame_width, image.height))
        local = _threshold_bbox(region, threshold)
        if local is None:
            reports.append(FrameReport(index=index, bounds=None))
            continue
        reports.append(
            FrameReport(
                index=index,
                bounds=Bounds(
                    left=x0 + local.left,
                    top=local.top,
                    right=x0 + local.right,
                    bottom=local.bottom,
                ),
                left_margin=local.left,
                right_margin=frame_width - local.right,
            )
        )
    return reports


def _gap_is_clean(image: Image.Image, frame_width: int, gap: int, threshold: int) -> bool:
    for index in range(FRAME_COUNT - 1):
        x0 = (index + 1) * frame_width + index * gap
        gap_region = image.crop((x0, 0, x0 + gap, image.height))
        if _threshold_bbox(gap_region, threshold) is not None:
            return False
    return True


def _connected_components(mask: np.ndarray) -> tuple[list[Component], np.ndarray]:
    height, width = mask.shape
    visited = np.zeros(mask.shape, dtype=bool)
    labels = np.zeros(mask.shape, dtype=np.int32)
    components: list[Component] = []
    next_label = 1
    ys, xs = np.nonzero(mask)
    for start_y, start_x in zip(ys.tolist(), xs.tolist()):
        if visited[start_y, start_x]:
            continue
        stack = [(start_y, start_x)]
        visited[start_y, start_x] = True
        labels[start_y, start_x] = next_label
        min_x = max_x = start_x
        min_y = max_y = start_y
        area = 0
        while stack:
            y, x = stack.pop()
            area += 1
            if x < min_x:
                min_x = x
            elif x > max_x:
                max_x = x
            if y < min_y:
                min_y = y
            elif y > max_y:
                max_y = y

            for ny in (y - 1, y, y + 1):
                if ny < 0 or ny >= height:
                    continue
                for nx in (x - 1, x, x + 1):
                    if nx < 0 or nx >= width or visited[ny, nx] or not mask[ny, nx]:
                        continue
                    visited[ny, nx] = True
                    labels[ny, nx] = next_label
                    stack.append((ny, nx))
        components.append(Component(next_label, Bounds(min_x, min_y, max_x + 1, max_y + 1), area))
        next_label += 1
    return components, labels


def _remove_edge_fragments(
    cell: Image.Image,
    threshold: int,
    edge_band_ratio: float,
    edge_fragment_max_ratio: float,
    min_fragment_area: int,
) -> tuple[Image.Image, int]:
    alpha = cell.getchannel("A")
    mask = np.array(alpha) > threshold
    components, labels = _connected_components(mask)
    if len(components) <= 1:
        return cell, 0

    main = max(components, key=lambda component: component.area)
    edge_band = max(4, int(round(cell.width * edge_band_ratio)))
    remove_mask = np.zeros(mask.shape, dtype=bool)
    removed = 0

    for component in components:
        if component is main:
            continue
        bounds = component.bounds
        touches_left = bounds.left <= edge_band
        touches_right = bounds.right >= cell.width - edge_band
        area_ratio = component.area / max(1, main.area)
        horizontally_overlaps_main = not (
            bounds.right < main.bounds.left - edge_band
            or bounds.left > main.bounds.right + edge_band
        )

        should_remove = component.area < min_fragment_area
        if (touches_left or touches_right) and area_ratio <= edge_fragment_max_ratio:
            should_remove = True
        if should_remove and not horizontally_overlaps_main:
            remove_mask |= labels == component.label
            removed += 1

    if removed == 0:
        return cell, 0

    cleaned = cell.copy()
    cleaned_alpha = np.array(cleaned.getchannel("A"))
    cleaned_alpha[remove_mask] = 0
    cleaned.putalpha(Image.fromarray(cleaned_alpha, "L"))
    return cleaned, removed


def _extract_source_crops(
    image: Image.Image,
    source_cell_width: int,
    threshold: int,
    filter_edge_fragments: bool,
    edge_band_ratio: float,
    edge_fragment_max_ratio: float,
    min_fragment_area: int,
) -> tuple[list[Image.Image], list[Bounds], int]:
    crops: list[Image.Image] = []
    bounds: list[Bounds] = []
    filtered_fragments = 0
    for index in range(FRAME_COUNT):
        x0 = index * source_cell_width
        cell = image.crop((x0, 0, x0 + source_cell_width, image.height))
        removed = 0
        if filter_edge_fragments:
            cell, removed = _remove_edge_fragments(
                cell,
                threshold,
                edge_band_ratio,
                edge_fragment_max_ratio,
                min_fragment_area,
            )
        filtered_fragments += removed
        local = _threshold_bbox(cell, threshold)
        if local is None:
            raise ValueError(f"frame {index + 1} is empty")
        absolute = Bounds(
            left=x0 + local.left,
            top=local.top,
            right=x0 + local.right,
            bottom=local.bottom,
        )
        crops.append(image.crop((absolute.left, absolute.top, absolute.right, absolute.bottom)))
        if removed:
            crops[-1] = cell.crop((local.left, local.top, local.right, local.bottom))
        bounds.append(absolute)
    return crops, bounds, filtered_fragments


def _resize_crop(crop: Image.Image, scale: float) -> Image.Image:
    if scale >= 0.999:
        return crop
    width = max(1, int(round(crop.width * scale)))
    height = max(1, int(round(crop.height * scale)))
    return crop.resize((width, height), Image.Resampling.LANCZOS)


def normalize_image(
    image: Image.Image,
    threshold: int,
    inner_padding: int,
    top_padding: int,
    bottom_padding: int,
    filter_edge_fragments: bool,
    edge_band_ratio: float,
    edge_fragment_max_ratio: float,
    min_fragment_area: int,
) -> tuple[Image.Image, float, int]:
    image = image.convert("RGBA")
    frame_width = _frame_width_for_runtime(image.width, FRAME_COUNT, FRAME_GAP)
    source_width = _source_cell_width(image.width, FRAME_COUNT)
    crops, _bounds, filtered_fragments = _extract_source_crops(
        image,
        source_width,
        threshold,
        filter_edge_fragments,
        edge_band_ratio,
        edge_fragment_max_ratio,
        min_fragment_area,
    )

    max_width = max(crop.width for crop in crops)
    max_height = max(crop.height for crop in crops)
    max_content_width = frame_width - inner_padding * 2
    max_content_height = image.height - top_padding - bottom_padding
    if max_content_width <= 0 or max_content_height <= 0:
        raise ValueError("padding leaves no room for sprites")

    scale = min(1.0, max_content_width / max_width, max_content_height / max_height)
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    baseline_y = image.height - bottom_padding

    for index, crop in enumerate(crops):
        resized = _resize_crop(crop, scale)
        frame_x = index * (frame_width + FRAME_GAP)
        paste_x = frame_x + (frame_width - resized.width) // 2
        paste_y = baseline_y - resized.height
        output.alpha_composite(resized, (paste_x, paste_y))

    return output, scale, filtered_fragments


def _summarize_frames(frames: list[FrameReport]) -> tuple[int, float, int, int]:
    visible = [frame for frame in frames if frame.bounds is not None]
    if not visible:
        return 0, 0.0, 0, 0
    centers = [
        (frame.left_margin or 0) + (frame.bounds.width - 1) / 2.0
        for frame in visible
        if frame.bounds is not None
    ]
    baselines = [frame.bounds.baseline for frame in visible if frame.bounds is not None]
    min_margin = min(
        min(frame.left_margin or 0, frame.right_margin or 0)
        for frame in visible
    )
    widths = [frame.bounds.width for frame in visible if frame.bounds is not None]
    center_drift = max(centers) - min(centers)
    baseline_drift = max(baselines) - min(baselines)
    width_drift = max(widths) - min(widths)
    return min_margin, center_drift, baseline_drift, width_drift


def _checker(size: tuple[int, int], cell: int = 24) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (255, 255, 255, 255))
    draw = ImageDraw.Draw(image)
    colors = ((238, 238, 238, 255), (210, 210, 210, 255))
    for y in range(0, height, cell):
        for x in range(0, width, cell):
            draw.rectangle(
                (x, y, min(width, x + cell), min(height, y + cell)),
                fill=colors[((x // cell) + (y // cell)) % 2],
            )
    return image


def _composite_for_preview(image: Image.Image, frame_width: int) -> Image.Image:
    preview = _checker(image.size)
    preview.alpha_composite(image.convert("RGBA"))
    draw = ImageDraw.Draw(preview)
    for index in range(FRAME_COUNT):
        x0 = index * (frame_width + FRAME_GAP)
        draw.rectangle((x0, 0, x0 + frame_width - 1, image.height - 1), outline=(55, 130, 230, 255), width=3)
        if index < FRAME_COUNT - 1:
            gap_x = x0 + frame_width
            draw.rectangle((gap_x, 0, gap_x + FRAME_GAP - 1, image.height - 1), outline=(230, 70, 70, 255), width=3)
    return preview


def write_preview(before: Image.Image, after: Image.Image, output_path: Path, scale: float = 0.35) -> None:
    frame_width = _frame_width_for_runtime(before.width, FRAME_COUNT, FRAME_GAP)
    before_preview = _composite_for_preview(before, frame_width)
    after_preview = _composite_for_preview(after, frame_width)
    scaled_size = (int(round(before.width * scale)), int(round(before.height * scale)))
    before_preview = before_preview.resize(scaled_size, Image.Resampling.LANCZOS)
    after_preview = after_preview.resize(scaled_size, Image.Resampling.LANCZOS)

    label_height = 24
    gutter = 10
    canvas = Image.new(
        "RGBA",
        (scaled_size[0], scaled_size[1] * 2 + label_height * 2 + gutter),
        (20, 20, 20, 255),
    )
    draw = ImageDraw.Draw(canvas)
    draw.text((8, 5), "Before", fill=(255, 255, 255, 255))
    canvas.alpha_composite(before_preview, (0, label_height))
    y_after_label = label_height + scaled_size[1] + gutter
    draw.text((8, y_after_label + 5), "After", fill=(255, 255, 255, 255))
    canvas.alpha_composite(after_preview, (0, y_after_label + label_height))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path)


def process_path(
    path: Path,
    dry_run: bool,
    overwrite: bool,
    backup_dir: Path | None,
    preview_dir: Path | None,
    threshold: int,
    inner_padding: int,
    top_padding: int,
    bottom_padding: int,
    filter_edge_fragments: bool,
    edge_band_ratio: float,
    edge_fragment_max_ratio: float,
    min_fragment_area: int,
) -> SheetReport:
    with Image.open(path) as opened:
        before = opened.convert("RGBA")

    frame_width = _frame_width_for_runtime(before.width, FRAME_COUNT, FRAME_GAP)
    source_width = _source_cell_width(before.width, FRAME_COUNT)
    before_starts = [index * frame_width + index * FRAME_GAP for index in range(FRAME_COUNT)]
    before_reports = _collect_frame_reports(before, before_starts, frame_width, threshold)
    gaps_clean_before = _gap_is_clean(before, frame_width, FRAME_GAP, threshold)

    after, scale, filtered_fragments = normalize_image(
        before,
        threshold,
        inner_padding,
        top_padding,
        bottom_padding,
        filter_edge_fragments,
        edge_band_ratio,
        edge_fragment_max_ratio,
        min_fragment_area,
    )
    after_reports = _collect_frame_reports(after, before_starts, frame_width, threshold)
    gaps_clean_after = _gap_is_clean(after, frame_width, FRAME_GAP, threshold)

    output_path: Path | None = None
    if not dry_run:
        if overwrite:
            if backup_dir is None:
                raise ValueError("--overwrite requires a backup directory")
            backup_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, backup_dir / path.name)
            after.save(path)
            output_path = path
        else:
            output_path = path.with_name(f"{path.stem}_normalized{path.suffix}")
            after.save(output_path)

    if preview_dir is not None and not dry_run:
        write_preview(before, after, preview_dir / f"{path.stem}_before_after.jpg")

    return SheetReport(
        path=path,
        size=before.size,
        frame_width=frame_width,
        source_cell_width=source_width,
        before_frames=before_reports,
        after_frames=after_reports,
        scale=scale,
        gaps_clean_before=gaps_clean_before,
        gaps_clean_after=gaps_clean_after,
        output_path=output_path,
        filtered_fragments=filtered_fragments,
    )


def _format_report(report: SheetReport) -> str:
    before_margin, before_center, before_base, before_width = _summarize_frames(report.before_frames)
    after_margin, after_center, after_base, after_width = _summarize_frames(report.after_frames)
    return (
        f"{report.path.name}: size={report.size[0]}x{report.size[1]} "
        f"frame={report.frame_width} source_cell={report.source_cell_width} "
        f"scale={report.scale:.3f} "
        f"filtered={report.filtered_fragments} "
        f"gap_before={'clean' if report.gaps_clean_before else 'DIRTY'} "
        f"gap_after={'clean' if report.gaps_clean_after else 'DIRTY'} "
        f"before_margin={before_margin}px before_center_drift={before_center:.1f}px "
        f"before_baseline_drift={before_base}px before_width_drift={before_width}px "
        f"after_margin={after_margin}px after_center_drift={after_center:.1f}px "
        f"after_baseline_drift={after_base}px after_width_drift={after_width}px"
    )


def _default_backup_dir(enemy_dir: Path) -> Path:
    stamp = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    return enemy_dir / "_backup_original" / stamp


def _resolve_targets(enemy_dir: Path, args_paths: list[str]) -> list[Path]:
    if args_paths:
        return [Path(item) if Path(item).is_absolute() else enemy_dir / item for item in args_paths]
    return [enemy_dir / name for name in DEFAULT_TARGETS]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", help="Specific sprite sheets to process. Defaults to known problem sheets.")
    parser.add_argument("--enemy-dir", default="assets/images/enemies", help="Enemy image directory.")
    parser.add_argument("--dry-run", action="store_true", help="Report normalization metrics without writing files.")
    parser.add_argument("--overwrite", action="store_true", help="Replace source PNGs after backing them up.")
    parser.add_argument("--backup-dir", default=None, help="Backup directory used with --overwrite.")
    parser.add_argument("--preview-dir", default=None, help="Write before/after preview JPGs when not in dry-run mode.")
    parser.add_argument("--alpha-threshold", type=int, default=ALPHA_THRESHOLD, help="Alpha threshold for sprite bounds.")
    parser.add_argument("--inner-padding", type=int, default=INNER_PADDING, help="Minimum left/right padding inside each runtime frame.")
    parser.add_argument("--top-padding", type=int, default=TOP_PADDING, help="Minimum top padding in pixels.")
    parser.add_argument("--bottom-padding", type=int, default=BOTTOM_PADDING, help="Bottom baseline padding in pixels.")
    parser.add_argument("--filter-edge-fragments", action="store_true", default=FILTER_EDGE_FRAGMENTS, help="Experimental: remove disconnected edge fragments before normalization.")
    parser.add_argument("--edge-band-ratio", type=float, default=EDGE_BAND_RATIO, help="Cell-edge band used to identify neighboring-frame fragments.")
    parser.add_argument("--edge-fragment-max-ratio", type=float, default=EDGE_FRAGMENT_MAX_RATIO, help="Maximum fragment/main area ratio removed when a fragment touches a cell edge.")
    parser.add_argument("--min-fragment-area", type=int, default=MIN_FRAGMENT_AREA, help="Always remove non-main components smaller than this area when they do not overlap the main body.")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.dry_run and args.overwrite:
        parser.error("--dry-run and --overwrite cannot be used together")

    enemy_dir = Path(args.enemy_dir)
    paths = _resolve_targets(enemy_dir, args.paths)
    missing = [path for path in paths if not path.exists()]
    if missing:
        for path in missing:
            print(f"missing: {path}", file=sys.stderr)
        return 2

    backup_dir = Path(args.backup_dir) if args.backup_dir else None
    if args.overwrite and backup_dir is None:
        backup_dir = _default_backup_dir(enemy_dir)

    preview_dir = Path(args.preview_dir) if args.preview_dir else None
    reports: list[SheetReport] = []
    for path in paths:
        report = process_path(
            path=path,
            dry_run=args.dry_run,
            overwrite=args.overwrite,
            backup_dir=backup_dir,
            preview_dir=preview_dir,
            threshold=args.alpha_threshold,
            inner_padding=args.inner_padding,
            top_padding=args.top_padding,
            bottom_padding=args.bottom_padding,
            filter_edge_fragments=args.filter_edge_fragments,
            edge_band_ratio=args.edge_band_ratio,
            edge_fragment_max_ratio=args.edge_fragment_max_ratio,
            min_fragment_area=args.min_fragment_area,
        )
        reports.append(report)
        print(_format_report(report))

    dirty_after = [report.path.name for report in reports if not report.gaps_clean_after]
    if dirty_after:
        print("ERROR: output gap validation failed for: " + ", ".join(dirty_after), file=sys.stderr)
        return 1
    if backup_dir is not None and not args.dry_run:
        print(f"backup_dir={backup_dir}")
    if preview_dir is not None and not args.dry_run:
        print(f"preview_dir={preview_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
