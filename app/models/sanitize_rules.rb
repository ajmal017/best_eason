class SanitizeRules

    BASIC = {
      :elements => %w[
        div span p font em strong br ol u a mark img object table 
        ul li tr td tbody thead th dl dt dd hr blockquote
      ],

      :attributes => {
        'a'          => ['href', 'title', 'target', 'class', 'data-uid', 'data-sid'],
        'span'       => ['style'],
        'p'          => ['style'],
        'abbr'       => ['title'],
        'blockquote' => ['cite'],
        'dfn'        => ['title'],
        'q'          => ['cite'],
        'img' => ['alt', 'src', 'title', 'border', 'align', 'height', 'width', 'class'],
        'time'       => ['datetime', 'pubdate']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]}
      }
    }

    STRICT = {
      :elements => %w[
        div span p font em strong br ol u a mark img object table 
        ul li tr td tbody thead th dl dt dd hr blockquote
      ],

      :attributes => {
        'a'          => ['href', 'title', 'target', 'class', 'data-uid', 'data-sid'],
        'span'       => [],
        'p'          => [],
        'abbr'       => ['title'],
        'blockquote' => ['cite'],
        'dfn'        => ['title'],
        'q'          => ['cite'],
        'img' => ['alt', 'src', 'title', 'border', 'align', 'height', 'width'],
        'time'       => ['datetime', 'pubdate']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto', :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]}
      }
    }

end
