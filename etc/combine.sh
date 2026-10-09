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
\documentclass[11pt,oneside,openany]{book}

\usepackage[margin=1in]{geometry}
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
    pdftitle={Attempts at Hartshorne's \textit{Algebraic Geometry} Exercises},
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

        # Include PDF and add hyperlinked TOC entry
        printf '\\includepdf[pages=-,pagecommand={\\combinedpagefooter},addtotoc={1,section,1,Section %s,sec:%s-%s}]{%s}\n\n' \
    "$section" "$chapter" "$section" "$pdf" >> "$MASTER"

        echo "Added: $pdf"

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