
#!/bin/bash
set -euo pipefail

# Locate the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# The project root is one directory above etc/
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Work from the project root
cd "$ROOT_DIR"

# Write generated files next to combine.sh
MASTER="$SCRIPT_DIR/combined_master.tex"
OUTPUT="$SCRIPT_DIR/Hartshorne-Solutions.pdf"

# Generate the LaTeX preamble
cat > "$MASTER" <<'EOF'
\documentclass[oneside,openany]{book}

\usepackage[margin=1in]{geometry}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{pdfpages}
\usepackage[hidelinks]{hyperref}
\usepackage{tikz}

% Replace original page numbers with continuous numbering
\newcommand{\combinedpagefooter}{%
    \thispagestyle{empty}%
    \begin{tikzpicture}[remember picture,overlay]
        \node[
            fill=white,
            minimum width=3cm,
            minimum height=0.6in,
            inner sep=0pt,
            font=\normalfont\normalsize
        ] at ([yshift=0.55in]current page.south)
        {\thepage};
    \end{tikzpicture}%
}

\hypersetup{
    pdftitle={Attempts at Hartshorne's Algebraic Geometry Exercises},
    bookmarksopen=true,
    bookmarksnumbered=true
}

\begin{document}

% Title page
\begin{titlepage}
    \centering
    \vspace*{3cm}

    {\Huge\bfseries
    Attempts at Hartshorne's \textit{Algebraic Geometry} Exercises\par}

    \vspace{2cm}
    {\Large James Lee\par}

    \vfill
    {\large \today\par}
\end{titlepage}

% Hyperlinked table of contents
\frontmatter
\tableofcontents

% Main content
\mainmatter

EOF

# Generate chapters and include PDFs
for chapter in 1 2 3 4 5; do

    chapter_dir="chapter${chapter}"

    if [[ ! -d "$chapter_dir" ]]; then
        continue
    fi

    case "$chapter" in
        1) title="Varieties" ;;
        2) title="Schemes" ;;
        3) title="Cohomology" ;;
        4) title="Curves" ;;
        5) title="Surfaces" ;;
    esac

    # Make chapter numbering agree with folder numbering
    printf '\\setcounter{chapter}{%s}\n' \
        "$((chapter - 1))" >> "$MASTER"

    printf '\\chapter{%s}\n\n' "$title" >> "$MASTER"

    # Sort section folders numerically
    while IFS= read -r -d '' section_dir; do

        [[ -d "$section_dir" ]] || continue

        section_name="${section_dir##*/}"

        if [[ ! "$section_name" =~ ^section([0-9]+)$ ]]; then
            continue
        fi

        section="${BASH_REMATCH[1]}"
        pdf="$section_dir/exercises.pdf"

        if [[ ! -f "$pdf" ]]; then
            echo "Skipping missing PDF: $pdf"
            continue
        fi

        # Hartshorne's original section titles
        case "${chapter}.${section}" in

            # Chapter I: Varieties
            1.1) section_title="Affine Varieties" ;;
            1.2) section_title="Projective Varieties" ;;
            1.3) section_title="Morphisms" ;;
            1.4) section_title="Rational Maps" ;;
            1.5) section_title="Nonsingular Varieties" ;;
            1.6) section_title="Nonsingular Curves" ;;
            1.7) section_title="Intersections in Projective Space" ;;
            1.8) section_title="What Is Algebraic Geometry?" ;;

            # Chapter II: Schemes
            2.1) section_title="Sheaves" ;;
            2.2) section_title="Schemes" ;;
            2.3) section_title="First Properties of Schemes" ;;
            2.4) section_title="Separated and Proper Morphisms" ;;
            2.5) section_title="Sheaves of Modules" ;;
            2.6) section_title="Divisors" ;;
            2.7) section_title="Projective Morphisms" ;;
            2.8) section_title="Differentials" ;;
            2.9) section_title="Formal Schemes" ;;

            # Chapter III: Cohomology
            3.1) section_title="Derived Functors" ;;
            3.2) section_title="Cohomology of Sheaves" ;;
            3.3) section_title="Cohomology of a Noetherian Affine Scheme" ;;
            3.4) section_title="\\v{C}ech Cohomology" ;;
            3.5) section_title="The Cohomology of Projective Space" ;;
            3.6) section_title="Ext Groups and Sheaves" ;;
            3.7) section_title="The Serre Duality Theorem" ;;
            3.8) section_title="Higher Direct Images of Sheaves" ;;
            3.9) section_title="Flat Morphisms" ;;
            3.10) section_title="Smooth Morphisms" ;;
            3.11) section_title="The Theorem on Formal Functions" ;;
            3.12) section_title="The Semicontinuity Theorem" ;;

            # Chapter IV: Curves
            4.1) section_title="Riemann-Roch Theorem" ;;
            4.2) section_title="Hurwitz's Theorem" ;;
            4.3) section_title="Embeddings in Projective Space" ;;
            4.4) section_title="Elliptic Curves" ;;
            4.5) section_title="The Canonical Embedding" ;;
            4.6) section_title='Classification of Curves in $\mathbb{P}^3$' ;;

            # Chapter V: Surfaces
            5.1) section_title="Geometry on a Surface" ;;
            5.2) section_title="Ruled Surfaces" ;;
            5.3) section_title="Monoidal Transformations" ;;
            5.4) section_title='The Cubic Surface in $\mathbb{P}^3$' ;;
            5.5) section_title="Birational Transformations" ;;
            5.6) section_title="Classification of Surfaces" ;;

            # Fallback for unknown sections
            *)
                section_title="Section ${section}"
                echo "Warning: Unknown title for ${chapter}.${section}"
                ;;
        esac

        # Correct section numbering, even if sections are skipped.
        # For example, chapter3/section2 becomes 3.2, not 3.1.
        printf '\\setcounter{section}{%s}\n' \
            "$((section - 1))" >> "$MASTER"

        # Include PDF and add hyperlinked TOC entry
        printf '\\includepdf[pages=-,pagecommand={\\combinedpagefooter},addtotoc={1,section,1,%s,sec:%s-%s}]{%s}\n\n' \
            "$section_title" "$chapter" "$section" "$pdf" >> "$MASTER"

        echo "Added: ${chapter}.${section} ${section_title}"

    done < <(
        printf '%s\0' "$chapter_dir"/section* | gsort -zV
    )

done

echo '\end{document}' >> "$MASTER"

# Compile twice to resolve hyperlinks and table of contents
pdflatex -interaction=nonstopmode -halt-on-error \
    -output-directory="$SCRIPT_DIR" "$MASTER"

pdflatex -interaction=nonstopmode -halt-on-error \
    -output-directory="$SCRIPT_DIR" "$MASTER"

# Rename final PDF
cp "$SCRIPT_DIR/combined_master.pdf" "$OUTPUT"

echo "Created $OUTPUT"
