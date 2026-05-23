alias z=zathura-sandbox

# mpv aliases
alias mpvv='mpv --no-video'
alias mpvvl='mpv --no-video --loop'

function jpeg-to-pdf
    convert -density 300 -gravity Center $argv out.pdf
end

function pdf-remove-annotations
    pdftk "$argv[1]" output - uncompress | sed '/^\/Annots/d' | pdftk - output "$argv[2]" compress
end
