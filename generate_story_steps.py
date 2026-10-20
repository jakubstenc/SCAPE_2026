#!/usr/bin/env python3
"""
generate_story_steps.py
Generates the 4-step transition story connecting empirical field photos of flower visits
to the topological pollinator-sharing web.
"""

import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.offsetbox import OffsetImage, AnnotationBbox
from PIL import Image

def get_badge(path, zoom=0.2):
    im = Image.open(path).convert("RGBA")
    return OffsetImage(im, zoom=zoom)

def build_story():
    os.makedirs("images", exist_ok=True)
    
    # -------------------------------------------------------------
    # Shared Data & Layout Coordinates
    # Canvas: 10 x 6.4 inches, dpi=300 -> 3000 x 1920 px
    # -------------------------------------------------------------
    
    # Plant positions (Top tier, y = 4.2)
    plant_data = {
        "achillea": {"name": "Achillea ptarmica", "sub": "Core Perennial Hub", "x": 2.7, "y": 4.2, "badge": "images/story_badge_achillea.png", "zoom": 0.145, "role": "core"},
        "succisa": {"name": "Succisa pratensis", "sub": "Core Perennial Hub", "x": 5.1, "y": 4.2, "badge": "images/story_badge_succisa.png", "zoom": 0.200, "role": "core"},
        "sanguisorba": {"name": "Sanguisorba officinalis", "sub": "Peripheral Flora", "x": 7.5, "y": 4.2, "badge": "images/story_badge_sanguisorba.png", "zoom": 0.088, "role": "periph"},
        "ranunculus": {"name": "Ranunculus acris", "sub": "Meadow Core", "x": 1.0, "y": 4.2, "badge": None, "color": "#1D2D6B", "core_color": "#FBBF24", "role": "core"},
        "centaurea": {"name": "Centaurea jacea", "sub": "Meadow Core", "x": 9.1, "y": 4.2, "badge": None, "color": "#1D2D6B", "core_color": "#FBBF24", "role": "core"}
    }
    
    # Pollinator positions (Bottom tier, y = 1.6)
    poll_data = {
        "eristalis": {"name": "Eristalis interruptus", "sub": "Hoverfly (Abundant Generalist)", "x": 3.0, "y": 1.6, "badge": "images/story_badge_eristalis.png", "zoom": 0.185},
        "butterfly": {"name": "Meadow Butterfly", "sub": "Coenonympha / Lycaenid", "x": 5.4, "y": 1.6, "badge": "images/story_badge_butterfly.png", "zoom": 0.090},
        "zygaena": {"name": "Zygaena burnet moth", "sub": "Day-flying Zygaenid", "x": 7.8, "y": 1.6, "badge": "images/story_badge_zygaena.png", "zoom": 0.052},
        "halictus": {"name": "Halictus wild bee", "sub": "Solitary Pollinator", "x": 1.2, "y": 1.6, "badge": None, "color": "#D97706"},
        "syrphid": {"name": "Syrphid fly sp.", "sub": "Flower visitor", "x": 9.0, "y": 1.6, "badge": None, "color": "#D97706"}
    }

    # Bipartite Edges (from pollinator to plant)
    # initial visits: eristalis->achillea, butterfly->succisa, zygaena->sanguisorba
    bip_edges = [
        {"p": "eristalis", "pl": "achillea", "initial": True, "weight": 4},
        {"p": "eristalis", "pl": "succisa", "initial": False, "weight": 4},
        {"p": "butterfly", "pl": "succisa", "initial": True, "weight": 3},
        {"p": "butterfly", "pl": "achillea", "initial": False, "weight": 2},
        {"p": "butterfly", "pl": "sanguisorba", "initial": False, "weight": 2},
        {"p": "zygaena", "pl": "sanguisorba", "initial": True, "weight": 3},
        {"p": "halictus", "pl": "ranunculus", "initial": False, "weight": 2},
        {"p": "halictus", "pl": "achillea", "initial": False, "weight": 2},
        {"p": "eristalis", "pl": "ranunculus", "initial": False, "weight": 3},
        {"p": "eristalis", "pl": "centaurea", "initial": False, "weight": 3},
        {"p": "syrphid", "pl": "centaurea", "initial": False, "weight": 2},
        {"p": "syrphid", "pl": "succisa", "initial": False, "weight": 2}
    ]

    def setup_fig():
        fig, ax = plt.subplots(figsize=(10.2, 6.2), dpi=300)
        fig.patch.set_facecolor("#FFFFFF")
        ax.set_facecolor("#FFFFFF")
        ax.set_xlim(0, 10.2)
        ax.set_ylim(0, 6.2)
        ax.axis("off")
        return fig, ax

    def draw_pill_header(ax, step_num, step_title, step_subtitle, tag_color, tag_bg, tag_border):
        # Pill banner
        box_props = dict(boxstyle="round,pad=0.38,rounding_size=0.3", facecolor=tag_bg, edgecolor=tag_border, linewidth=1.2)
        ax.text(5.1, 5.76, f"  STEP {step_num} • {step_title.upper()}  ", 
                ha="center", va="center", fontsize=11.5, fontweight="bold", color=tag_color,
                bbox=box_props, family="sans-serif")
        # Subtitle explanation
        ax.text(5.1, 5.34, step_subtitle, 
                ha="center", va="center", fontsize=11, fontstyle="italic", color="#475569", family="sans-serif")

    def draw_tier_labels(ax):
        ax.text(0.4, 4.35, "CO-FLOWERING\nPLANTS", ha="center", va="center", fontsize=9, fontweight="bold", color="#64748B", family="sans-serif", alpha=0.85)
        ax.text(0.4, 1.60, "FLOWER\nVISITORS", ha="center", va="center", fontsize=9, fontweight="bold", color="#B45309", family="sans-serif", alpha=0.85)

    def draw_nodes(ax, highlight_eristalis=False):
        # Draw Plants
        for k, p in plant_data.items():
            if p["badge"]:
                # Outer shadow / ring
                rim_color = "#1D2D6B" if p["role"] == "core" else "#E06A55"
                circle_bg = patches.Circle((p["x"], p["y"]), 0.72, facecolor="white", edgecolor=rim_color, linewidth=2.4, zorder=4)
                ax.add_patch(circle_bg)
                ab = AnnotationBbox(get_badge(p["badge"], zoom=p["zoom"]), (p["x"], p["y"]), frameon=False, zorder=5)
                ax.add_artist(ab)
            else:
                # Stylized core circle
                ax.add_patch(patches.Circle((p["x"], p["y"]), 0.38, facecolor=p["color"], edgecolor="white", linewidth=2.0, zorder=4))
                ax.add_patch(patches.Circle((p["x"], p["y"]), 0.18, facecolor=p["core_color"], edgecolor="none", zorder=5))
            
            # Label
            lbl_color = "#0F172A" if p.get("role") == "core" else "#991B1B"
            ax.text(p["x"], p["y"] - 0.95, p["name"], ha="center", va="top", fontsize=10.5, fontweight="bold", fontstyle="italic", color=lbl_color, family="sans-serif", zorder=6)
            ax.text(p["x"], p["y"] - 1.18, p["sub"], ha="center", va="top", fontsize=8.5, color="#64748B", family="sans-serif", zorder=6)

        # Draw Pollinators
        for k, poll in poll_data.items():
            if poll["badge"]:
                rim_color = "#F59E0B" if (highlight_eristalis and k == "eristalis") else "#D97706"
                lw = 3.8 if (highlight_eristalis and k == "eristalis") else 2.0
                
                if highlight_eristalis and k == "eristalis":
                    # Golden halo glow
                    glow = patches.Circle((poll["x"], poll["y"]), 0.88, facecolor="#FEF3C7", edgecolor="#F59E0B", linewidth=1.5, alpha=0.7, zorder=3)
                    ax.add_patch(glow)

                circle_bg = patches.Circle((poll["x"], poll["y"]), 0.68, facecolor="white", edgecolor=rim_color, linewidth=lw, zorder=4)
                ax.add_patch(circle_bg)
                ab = AnnotationBbox(get_badge(poll["badge"], zoom=poll["zoom"]), (poll["x"], poll["y"]), frameon=False, zorder=5)
                ax.add_artist(ab)
            else:
                ax.add_patch(patches.Circle((poll["x"], poll["y"]), 0.32, facecolor=poll["color"], edgecolor="white", linewidth=1.8, zorder=4))
                ax.add_patch(patches.Circle((poll["x"], poll["y"]), 0.14, facecolor="#FEF3C7", edgecolor="none", zorder=5))

            lbl_color = "#9A3412" if (highlight_eristalis and k == "eristalis") else "#451A03"
            ax.text(poll["x"], poll["y"] - 0.88, poll["name"], ha="center", va="top", fontsize=10, fontweight="bold", color=lbl_color, family="sans-serif", zorder=6)
            ax.text(poll["x"], poll["y"] - 1.09, poll["sub"], ha="center", va="top", fontsize=8, color="#78716C", family="sans-serif", zorder=6)

    # =============================================================
    # PLOT 1A: Observed Individual Flower Visits
    # =============================================================
    fig, ax = setup_fig()
    draw_pill_header(ax, 1, "Empirical Flower Visits in the Meadow",
                     "Field surveys record individual insect visits on co-flowering plant species",
                     "#15803D", "#F0FDF4", "#86EFAC")
    draw_tier_labels(ax)
    
    # Active initial visits
    for edge in bip_edges:
        p_info = poll_data[edge["p"]]
        pl_info = plant_data[edge["pl"]]
        if edge["initial"]:
            # Vibrant glowing visit link
            ax.plot([p_info["x"], pl_info["x"]], [p_info["y"], pl_info["y"]],
                    color="#0284C7", linewidth=2.8, zorder=2, alpha=0.9, solid_capstyle="round")
            # Subtle directional pulse dot
            mx = 0.5 * (p_info["x"] + pl_info["x"])
            my = 0.5 * (p_info["y"] + pl_info["y"])
            ax.plot(mx, my, marker="o", markersize=6, color="#38BDF8", zorder=3)
        else:
            # Ghost line
            ax.plot([p_info["x"], pl_info["x"]], [p_info["y"], pl_info["y"]],
                    color="#F1F5F9", linewidth=1.0, zorder=1, alpha=0.5)

    draw_nodes(ax, highlight_eristalis=False)
    
    # Callout annotations on visits
    ax.annotate("Direct visit:\nHoverfly on Achillea", xy=(2.85, 2.9), xytext=(1.4, 3.1),
                arrowprops=dict(arrowstyle="->", color="#0284C7", lw=1.2),
                fontsize=8.5, fontweight="bold", color="#0369A1", family="sans-serif",
                bbox=dict(boxstyle="round,pad=0.2", facecolor="#F0F9FF", edgecolor="#BAE6FD", lw=0.8),
                zorder=7)

    plt.tight_layout()
    fig.savefig("images/story_step1a_few_visits.png", dpi=300)
    plt.close(fig)
    print("Saved images/story_step1a_few_visits.png")

    # =============================================================
    # PLOT 1B: Complete Bipartite Network
    # =============================================================
    fig, ax = setup_fig()
    draw_pill_header(ax, 2, "The Bipartite Interaction Web",
                     "Accumulated observations assemble into a two-mode plant–pollinator interaction network",
                     "#1D4ED8", "#EFF6FF", "#93C5FD")
    draw_tier_labels(ax)

    # Draw all bipartite edges with natural translucent slate styling
    for edge in bip_edges:
        p_info = poll_data[edge["p"]]
        pl_info = plant_data[edge["pl"]]
        alpha = 0.70 if edge["weight"] >= 3 else 0.45
        lw = 1.4 + 0.4 * edge["weight"]
        ax.plot([p_info["x"], pl_info["x"]], [p_info["y"], pl_info["y"]],
                color="#64748B", linewidth=lw, zorder=2, alpha=alpha, solid_capstyle="round")

    draw_nodes(ax, highlight_eristalis=False)
    
    ax.text(5.1, 0.28, "Plants and insects form a bipartite web: links represent empirical feeding interactions",
            ha="center", va="center", fontsize=9.5, color="#64748B", family="sans-serif")

    plt.tight_layout()
    fig.savefig("images/story_step1b_full_bipartite.png", dpi=300)
    plt.close(fig)
    print("Saved images/story_step1b_full_bipartite.png")

    # =============================================================
    # PLOT 2A: The Shared Pollinator Bridge
    # =============================================================
    fig, ax = setup_fig()
    draw_pill_header(ax, 3, "The Living Bridge: Shared Pollinators",
                     "Plants do not interact directly — shared flower visitors carry pollen between them!",
                     "#B45309", "#FEF3C7", "#FCD34D")
    draw_tier_labels(ax)

    # Dim other bipartite edges
    for edge in bip_edges:
        p_info = poll_data[edge["p"]]
        pl_info = plant_data[edge["pl"]]
        if edge["p"] != "eristalis" or (edge["pl"] not in ["achillea", "succisa"]):
            ax.plot([p_info["x"], pl_info["x"]], [p_info["y"], pl_info["y"]],
                    color="#CBD5E1", linewidth=0.9, zorder=1, alpha=0.35)

    # Highlight Eristalis visits to Achillea and Succisa
    erist = poll_data["eristalis"]
    ach = plant_data["achillea"]
    suc = plant_data["succisa"]

    ax.plot([erist["x"], ach["x"]], [erist["y"], ach["y"]],
            color="#F59E0B", linewidth=3.8, zorder=2, solid_capstyle="round")
    ax.plot([erist["x"], suc["x"]], [erist["y"], suc["y"]],
            color="#F59E0B", linewidth=3.8, zorder=2, solid_capstyle="round")

    # GLOWING DIRECT SHARING BRIDGE ARC (Achillea <-> Succisa)
    # Using FancyArrowPatch for a glorious curved royal blue bridge
    arc = patches.FancyArrowPatch(
        (ach["x"], ach["y"] + 0.65), (suc["x"], suc["y"] + 0.65),
        connectionstyle="arc3,rad=-0.42",
        color="#1D4ED8", linewidth=3.8, zorder=6,
        arrowstyle="<|-|>", mutation_scale=16
    )
    # Background glow for arc
    arc_glow = patches.FancyArrowPatch(
        (ach["x"], ach["y"] + 0.65), (suc["x"], suc["y"] + 0.65),
        connectionstyle="arc3,rad=-0.42",
        color="#93C5FD", linewidth=7.5, zorder=5, alpha=0.55,
        arrowstyle="-"
    )
    ax.add_patch(arc_glow)
    ax.add_patch(arc)

    # Arc Label Badge
    arc_box = dict(boxstyle="round,pad=0.32", facecolor="#EFF6FF", edgecolor="#2563EB", linewidth=1.2)
    ax.text(3.9, 5.15, "🔄 SHARED POLLINATOR LINK\n(Indirect interaction: pollen transfer & facilitation/competition)",
            ha="center", va="center", fontsize=8.5, fontweight="bold", color="#1E40AF",
            bbox=arc_box, family="sans-serif", zorder=7)

    draw_nodes(ax, highlight_eristalis=True)

    plt.tight_layout()
    fig.savefig("images/story_step2a_sharing_bridge.png", dpi=300)
    plt.close(fig)
    print("Saved images/story_step2a_sharing_bridge.png")

    # =============================================================
    # PLOT 2B: Full Plant-Plant Pollinator Sharing Web
    # Transitions directly into the Meadow Network seen on next slide!
    # =============================================================
    fig, ax = setup_fig()
    draw_pill_header(ax, 4, "Projection: The Meadow Pollinator-Sharing Web",
                     "Projecting shared visitors yields the unipartite plant web anchored by stable core hubs",
                     "#3730A3", "#EEF2FF", "#C7D2FE")

    # Organic layout matching plant_step4_coreness on next slide
    # Center core hubs: Centaurea (center), Succisa (right), Achillea (left), Selinum, Pimpinella, Ranunculus
    # Center of plot is (5.1, 2.8)
    cx, cy = 5.1, 2.7
    scale = 0.95

    net_core = {
        "achillea": {"name": "Achillea ptarmica", "x": cx - 1.55 * scale, "y": cy + 0.45 * scale, "badge": "images/story_badge_achillea.png", "zoom": 0.135, "role": "core"},
        "succisa": {"name": "Succisa pratensis", "x": cx + 1.65 * scale, "y": cy - 0.40 * scale, "badge": "images/story_badge_succisa.png", "zoom": 0.180, "role": "core"},
        "centaurea": {"name": "Centaurea jacea", "x": cx + 0.05 * scale, "y": cy + 0.20 * scale, "badge": None, "role": "core"},
        "selinum": {"name": "Selinum carvifolia", "x": cx + 0.20 * scale, "y": cy - 1.45 * scale, "badge": None, "role": "core"},
        "pimpinella": {"name": "Pimpinella saxifraga", "x": cx + 1.25 * scale, "y": cy + 1.35 * scale, "badge": None, "role": "core"},
        "ranunculus": {"name": "Ranunculus acris", "x": cx - 1.15 * scale, "y": cy - 1.05 * scale, "badge": None, "role": "core"}
    }

    # Peripheral plants (spokes)
    net_periph = {
        "sanguisorba": {"name": "Sanguisorba officinalis", "x": cx + 3.25 * scale, "y": cy + 1.10 * scale, "badge": "images/story_badge_sanguisorba.png", "zoom": 0.078, "role": "periph"},
        "cirsium": {"name": "Cirsium palustre", "x": cx + 0.20 * scale, "y": cy + 2.45 * scale, "badge": None, "role": "periph"},
        "lathyrus": {"name": "Lathyrus pratensis", "x": cx - 3.10 * scale, "y": cy - 1.70 * scale, "badge": None, "role": "periph"},
        "flammula": {"name": "Ranunculus flammula", "x": cx + 3.00 * scale, "y": cy - 1.80 * scale, "badge": None, "role": "periph"},
        "lychnis": {"name": "Lychnis flos-cuculi", "x": cx - 3.20 * scale, "y": cy + 1.25 * scale, "badge": None, "role": "periph"},
        "hypericum": {"name": "Hypericum maculatum", "x": cx - 2.10 * scale, "y": cy + 2.10 * scale, "badge": None, "role": "periph"}
    }

    all_net_plants = {**net_core, **net_periph}

    # Core-core links (backbone)
    core_pairs = [
        ("achillea", "succisa", 4.2),
        ("achillea", "centaurea", 3.5),
        ("succisa", "centaurea", 3.8),
        ("achillea", "ranunculus", 2.8),
        ("succisa", "selinum", 3.0),
        ("centaurea", "pimpinella", 2.9),
        ("pimpinella", "succisa", 2.6),
        ("selinum", "ranunculus", 2.5),
        ("centaurea", "selinum", 2.8)
    ]

    # Spoke links
    spoke_pairs = [
        ("sanguisorba", "succisa", 1.8),
        ("sanguisorba", "centaurea", 1.6),
        ("cirsium", "centaurea", 1.5),
        ("cirsium", "pimpinella", 1.4),
        ("lathyrus", "ranunculus", 1.6),
        ("lathyrus", "achillea", 1.4),
        ("flammula", "succisa", 1.5),
        ("flammula", "selinum", 1.3),
        ("lychnis", "achillea", 1.5),
        ("hypericum", "achillea", 1.4),
        ("hypericum", "centaurea", 1.2)
    ]

    # Draw Spoke links first
    for u, v, w in spoke_pairs:
        p1, p2 = all_net_plants[u], all_net_plants[v]
        ax.plot([p1["x"], p2["x"]], [p1["y"], p2["y"]],
                color="#93C5FD", linewidth=1.2, alpha=0.55, zorder=2)

    # Draw Core backbone links with prominent royal blue
    for u, v, w in core_pairs:
        p1, p2 = all_net_plants[u], all_net_plants[v]
        # Highlight Achillea-Succisa backbone especially
        if (u == "achillea" and v == "succisa") or (u == "succisa" and v == "achillea"):
            ax.plot([p1["x"], p2["x"]], [p1["y"], p2["y"]],
                    color="#93C5FD", linewidth=6.5, alpha=0.5, zorder=2)
            ax.plot([p1["x"], p2["x"]], [p1["y"], p2["y"]],
                    color="#1D4ED8", linewidth=3.8, zorder=3)
        else:
            ax.plot([p1["x"], p2["x"]], [p1["y"], p2["y"]],
                    color="#1D4ED8", linewidth=2.4, alpha=0.85, zorder=3)

    # Draw Nodes
    # Peripherals
    for k, p in net_periph.items():
        if p["badge"]:
            circle_bg = patches.Circle((p["x"], p["y"]), 0.55, facecolor="white", edgecolor="#E06A55", linewidth=2.2, zorder=4)
            ax.add_patch(circle_bg)
            ab = AnnotationBbox(get_badge(p["badge"], zoom=p["zoom"]), (p["x"], p["y"]), frameon=False, zorder=5)
            ax.add_artist(ab)
            ax.text(p["x"], p["y"] - 0.72, p["name"], ha="center", va="top", fontsize=8.5, fontstyle="italic", color="#991B1B", family="sans-serif", zorder=6)
        else:
            ax.add_patch(patches.Circle((p["x"], p["y"]), 0.16, facecolor="#F87171", edgecolor="white", linewidth=1.2, zorder=4))
            ax.text(p["x"], p["y"] - 0.32, p["name"], ha="center", va="top", fontsize=7.5, fontstyle="italic", color="#B91C1C", family="sans-serif", zorder=6)

    # Core Hubs
    for k, p in net_core.items():
        if p["badge"]:
            # Glowing core halo
            glow = patches.Circle((p["x"], p["y"]), 0.82, facecolor="#EFF6FF", edgecolor="#1D4ED8", linewidth=1.5, alpha=0.7, zorder=3)
            ax.add_patch(glow)
            circle_bg = patches.Circle((p["x"], p["y"]), 0.68, facecolor="white", edgecolor="#1E3A8A", linewidth=2.8, zorder=4)
            ax.add_patch(circle_bg)
            ab = AnnotationBbox(get_badge(p["badge"], zoom=p["zoom"]), (p["x"], p["y"]), frameon=False, zorder=5)
            ax.add_artist(ab)
            ax.text(p["x"], p["y"] - 0.90, p["name"], ha="center", va="top", fontsize=9.5, fontweight="bold", fontstyle="italic", color="#0F172A", family="sans-serif", zorder=6)
            ax.text(p["x"], p["y"] - 1.10, "CORE HUB", ha="center", va="top", fontsize=7.5, fontweight="bold", color="#1D4ED8", family="sans-serif", zorder=6)
        else:
            ax.add_patch(patches.Circle((p["x"], p["y"]), 0.34, facecolor="#1E3A8A", edgecolor="white", linewidth=2.0, zorder=4))
            ax.add_patch(patches.Circle((p["x"], p["y"]), 0.16, facecolor="#FBBF24", edgecolor="none", zorder=5))
            ax.text(p["x"], p["y"] - 0.50, p["name"], ha="center", va="top", fontsize=8.5, fontweight="bold", fontstyle="italic", color="#0F172A", family="sans-serif", zorder=6)

    # Legend in lower right corner
    leg_box = dict(boxstyle="round,pad=0.4", facecolor="#F8FAFC", edgecolor="#CBD5E1", linewidth=1.0)
    leg_text = "● Core Perennial Hubs (Backbone)\n● Peripheral Spokes (Specialist / Ephemeral)"
    ax.text(9.9, 0.40, leg_text, ha="right", va="bottom", fontsize=8.5, color="#334155",
            bbox=leg_box, family="sans-serif", zorder=7)

    plt.tight_layout()
    fig.savefig("images/story_step2b_sharing_web.png", dpi=300)
    plt.close(fig)
    print("Saved images/story_step2b_sharing_web.png")

if __name__ == "__main__":
    build_story()
