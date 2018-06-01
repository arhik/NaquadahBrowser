global PATH = pwd() * "/.julia/v0.6/NaquadahBrowser/src/SamplePages/BrowserImages/"

using Cairo, Gtk, Gtk.ShortNames


export
          DrawViewport, DrawContent, DrawShape,
          DrawText, DrawSelectedText, setcolor, drawNode, lastClipParent,
          GetlastColor, setTextContext


#          include("Events.jl")
#          include("GraphFlags.jl")
#          include("LayoutBuild.jl")

# dashes_by_name = [  "solid", "dot", "dotdashed", "longdashed", "dash", "dotdotdashed", "dotdotdotdashed"   ]
# ======================================================================================
# As I aquire a better understanding of how Cairo works, no doubt, this file will change
# drastically!
# ======================================================================================



# ======================================================================================
# Accept color values with or without alpha
# ======================================================================================
setcolor( ctx::Cairo.CairoContext, r, g, b) = set_source_rgb(ctx, r, g, b);
setcolor( ctx::Cairo.CairoContext, r, g, b, a) = set_source_rgba(ctx, r, g, b, a);
# setcolor( ctx::Cairo.CairoContext, color) = set_source_rgba(ctx, color...);
# setcolor( ctx::Cairo.CairoContext, node::Element) = set_source_rgba(ctx, node.shape.color...);
# setcolor( ctx::Cairo.CairoContext, shape::Draw) = set_source_rgba(ctx, shape.color...);

# ======================================================================================
# First draw all page elements (not controls) that flow and then draw "fixed" elements
# ======================================================================================
function DrawViewport(ctx::Cairo.CairoContext, document::Page, node::Element)
    DrawContent(ctx, document, node)
    DrawContent(ctx, document, document.fixed)
end
# ======================================================================================
"""
## DrawContent(ctx, document, node, clipPath=nothing)

This takes a node and draws it along with all its children.

# Examples
```julia-repl
```
[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
# PROBLEM: This draws the children of a given node and not nesesarily the node itself.
#          At times, though, we don't want to draw all the children of a node but
#          specifically one node.
# ======================================================================================
function DrawContent(ctx::Cairo.CairoContext, document::Page, node::Element, clipPath=nothing)
      rows = node.rows
      border = get(node.shape.border,  Border(0,0,0,0,0,0, 0,[],[0,0,0,0]))
      padding = get(node.shape.padding, BoxOutline(0,0,0,0,0,0))
      Shape = node.shape

      if Shape.flags[Clip]
          clipPath = getBorderBox(Shape, border, padding)
      end

      if clipPath !== nothing
          rectangle(ctx, clipPath... )
          clip(ctx)
      end

  for row in rows
      for child in row.nodes
          if row.top < (Shape.top + Shape.height) # && !node.shape.flags[DisplayNone]
              drawNode(ctx, document, row, child.shape, child, clipPath)
          end
      end
  end

      # Scroll bars.......... TODO: fix
      if Shape.flags[IsVScroll]
          VScroller(ctx, document, node, Shape, clipPath)
      end
      if Shape.flags[Clip] #|| clipPath === nothing
         reset_clip(ctx)
         clipPath = nothing
      end
end
# ======================================================================================
# ======================================================================================
function drawNode(ctx, document, row, shape, node, clipPath)
             if isa(shape, TextLine)
                 DrawText(ctx, node, clipPath)
             else
                 DrawShape(ctx, node, shape, clipPath)
                 DrawContent(ctx, document, node, clipPath)     # Now draw children
             end
             # if isa(node, Text)
             #     s = node.parent.shape
             #     setcolor(ctx, .3,.3,.3)
             #     rectangle(ctx, s.left,s.top,s.width+3,s.height+3 )
             #     stroke(ctx);
             # end
end
#...............................................................................
function lastClipParent(node)
    while node.parent !== node
        if node.shape.flags[Clip]
            return node
        end
        node = node.parent
    end
    return node
end

function drawNode(ctx, document, node)

    box = lastClipParent(node) #document.children[1].children[3];

    shape = node.shape
    WinShape = box.shape
    border = get(WinShape.border,  Border(0,0,0,0,0,0, 0,[],[0,0,0,0]))
    padding = get(WinShape.padding, BoxOutline(0,0,0,0,0,0))
    clipPath = getBorderBox(WinShape, border, padding)

    rectangle(ctx, clipPath... )
    clip(ctx)
                 # DrawText(ctx, row, shape)
             #else
                 DrawShape(ctx, node, shape, clipPath)
            if !isa(node, Text)
                 DrawContent(ctx, document, node, clipPath)     # Now draw children
            end
    reset_clip(ctx)

end
# ======================================================================================
# http://www.nongnu.org/guile-cairo/docs/html/Patterns.html
# Draw a circle.
# TODO: remove node from function
"""
## DrawShape(ctx::CairoContext, node, shape, clipPath)

Draw ...


[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
function DrawShape(ctx::CairoContext, node::Element, shape::Draw, clipPath)
    Cairo.save(ctx)
    path = GetPath(shape)
    # set_antialias(ctx,4)
    setPath(ctx::CairoContext, path)
    clip(ctx);
  if shape.flags[HasImage]
        DOM =  node.DOM
            if haskey(DOM, "image")
                imagePath = PATH * DOM["image"] # "Mountains.png"
            end
            BackgroundImage(ctx, path.wide, path.tall, shape.left, shape.top, imagePath)

  elseif  shape.flags[LinearGrad]
        linearGrad(ctx, path, shape.gradient)
  elseif  shape.flags[RadialGrad]
        radialGrad(ctx, path, shape.gradient)
  else
          # set_antialias(ctx,6)
          if isdefined(shape, :color) &&  length(shape.color) > 2
            setPath(ctx::CairoContext, path)
            setcolor(ctx, shape.color...)
            fill(ctx);
          end
  end
  restore(ctx)
  #reset_clip(ctx)
     thickness = setClipPath(ctx::CairoContext, path)
     clip(ctx)
          if isdefined(path.border, :color) && length(path.border.color) > 2
                setcolor( ctx, path.border.color...)
                # TODO: add clipping for the border path as well to clean up edges.
                #if clipPath !== nothing
                    # rectangle(ctx, clipPath... )
                    # clip(ctx)
                #end
                #clip_preserve()
                # save(ctx)
                        set_line_type(ctx, path.border.style)
                        set_line_width(ctx, thickness);
                        setborderPath(ctx::CairoContext, path)
                        stroke(ctx)
                # restore(ctx)

                # reset_clip(ctx)
          end
        reset_clip(ctx)
end
# ======================================================================================
# Temporary shortcut: draw the virticle scroll bar
"""
## VScroller(ctx::CairoContext, document, node, shape, clipPath)

Temporary hack: draw the virticle scroll bar

# Examples
```julia-repl
```
[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
function VScroller(ctx::CairoContext, document::Page, node::Element, shape::Draw, clipPath)

    canvas = document.canvas
    ctx = getgc(canvas)
    winHeight = document.height # height(canvas)

        border = get(shape.border,  Border(0,0,0,0,0,0, 0,[],[0,0,0,0]))
        padding = get(shape.padding, BoxOutline(0,0,0,0,0,0))
        l,t,w,h = getBorderBox(shape, border, padding)
        h/node.scroll.contentHeight
        r, b = l+w-12, t+h-12

        realTop = abs(t)

        setcolor(ctx, .3,.3,.3, .3)
        rectangle(ctx,r,t,12,h )
        fill(ctx);
        #.............................................................
         height       = node.shape.height - node.shape.top    # Height of the viewport and of the scrollbarArea
         scrollHeight = node.scroll.contentHeight     # Height of the content
         scrollTop    = node.scroll.y      # Scrolled position of the content from the top
         #.............................................................
         scrollButHeight = height / (scrollHeight / height)
         y = scrollTop / (scrollHeight / height)
         #.............................................................
         #.............................................................

        setcolor(ctx, .4,.4,.4, 1)
        rectangle(ctx,r+1,t-y,10,scrollButHeight )
        fill(ctx);
end




















#  (from Cairo/src/cairo.jl):
#  function CairoImageSurface(img::Array{Uint32,2}, format::Integer; flipxy::Bool = true)
# CairoImageSurface(ary, fmt) copies the input array, but you can access the raw pixels
#  (R/W) by using the .data attribute of the surface.
# ======================================================================================
#
# CALLED FROM:
# ======================================================================================
#=
inline_png2 = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00d\x00\x00\x00d\x08\x02\x00\x00\x00\xff\x80\x02\x03\x00\x00\x00\x06bKGD\x00\xff\x00\xff\x00\xff\xa0\xbd\xa7\x93\x00\x00\x01=IDATx\x9c\xed\xdc\xc1i\x85@\x14@\xd1IH!\x96bi\x96f)\x96\x92E@!\x01\x7f\xeeF\xfdp\xce\xca\x9d\xc3\xe5\xb9{\xce\xc7\xb2,\x83\xff\xf9\xbc\xfb\x00\xefD\xac@\xac@\xac@\xac@\xac@\xac@\xac@\xac\xe0\xeb\xee\x03\xfc\xb1\xaec]\xc7\x18c\x9e\xc7<\xdf{\x96_LV V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V\xf0j[\xf9gq\xf8J\xdbv<\\\xff\xf6\xd3\xfd\xe8\xe7\xc5\xdam\xdb\x11\xee2\xa7\xb1|\x86\xc1\xab\xc9\xba~m\x7f\x1f\xa8i\x1a\xd3t\xf5\xdbO=/\xd6\xba\x1e\xb1\xfca\xf1\xbe\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\xc4\n\x9ew\x1f\xfc\xf3\xae\x81\xdf\x99\xac@\xac@\xac@\xac@\xac@\xac@\xac@\xac@\xac\xe0\x1b\xaf\xef\x1c\xd4\x17\xfe\xcaX\x00\x00\x00\x00IEND\xaeB`\x82"
png_stream = IOBuffer();
write(png_stream,inline_png2);
seekstart(png_stream);

imagesurface = read_from_png(png_stream);
set_source_surface(cr, imagesurface, 0, 0);
paint(cr);
=#




type NQCircle
    border::Border
    radius::Float64
    left::Float64
    top::Float64
    wide::Float64
    tall::Float64
    NQCircle() = new()
end
type NQBox
    border::Border
    padding::BoxOutline
    left::Float64
    top::Float64
    wide::Float64
    tall::Float64
    right::Float64
    bottom::Float64
    NQBox() = new()
end

# ======================================================================================
"""
## BackgroundImage(ctx::CairoContext, wide::Float64, tall::Float64, l::Float64, t::Float64, path)

Draw the background image at 100% width and height.
# Examples
 Stream: https://github.com/JuliaGraphics/Cairo.jl/blob/master/samples/sample_imagestream.jl
 Alpha:  https://github.com/JuliaGraphics/Cairo.jl/blob/master/samples/sample_alpha_paint.jl


[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
function BackgroundImage(ctx::CairoContext, wide::Float64, tall::Float64, l::Float64, t::Float64, path)

     image = read_from_png(path);
     w = image.width;  # w = (image.width/2);
     h = image.height; # h = (image.height/2);

     scale(ctx, wide/w, tall/h);
     translate(ctx,  (l*((w/wide)))-(l),  (t*(w/tall))-(t)); # 1029 >= w*2   l + l*(wide/w) + wide*(wide/w) =1014
     set_source_surface(ctx, image, l, t);
     paint(ctx);
     reset_transform(ctx)
end
# ======================================================================================
# Draw a linear gradient
"""
## linearGrad(ctx::CairoContext, shape, gradient)

Draw a linear gradient.

[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
function linearGrad(ctx::CairoContext, shape, gradient)
    pat = pattern_create_linear(shape.left+0.0, shape.top+180.0, shape.left+180.0, shape.top+0.0 );
    for i in 1:length(gradient)
            pattern_add_color_stop_rgba(pat, gradient[i] ...);
    end
    setPath(ctx, shape)
    set_source(ctx, pat);
    fill(ctx);
    destroy(pat);
end
"""
## radialGrad(ctx, path, gradient)

Draw a radial gradient.

[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
function radialGrad(ctx::CairoContext, path, gradient)
    offsetX, offsetY = 0, 0 #This can be added later to the second x,y coords
    # color, offset, start
    pat = pattern_create_radial(path.left,         path.top,         1,
                                path.left+offsetX, path.top+offsetY, path.wide*.5);
            pattern_add_color_stop_rgba(pat, 0, 0, 1, 0, 1);
            pattern_add_color_stop_rgba(pat, .5, 0, 0, 0, 1);
            pattern_add_color_stop_rgba(pat, 1, 0, 0, 1, 1);
            set_source(ctx, pat);
            setPath(ctx, path)
            fill(ctx);
            destroy(pat);
end
# ======================================================================================
"""
## GetPath(shape::NBox)

...

## GetPath(shape::Circle)
[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================
function GetPath(shape::NBox)
    b = NQBox()
    b.border  = get(shape.border,  Border(0,0,0,0,0,0, "solid",[],[0,0,0,0]))
    b.padding = get(shape.padding, BoxOutline(0,0,0,0,0,0))


        # b.left = shape.left   - b.padding.left   - (b.border.left *.5)
        # b.top  = shape.top    - b.padding.top    - (b.border.top *.5)
        # b.wide = shape.width  + b.padding.width  + (b.border.width)
        # b.tall = shape.height + b.padding.height + (b.border.height)

    b.left, b.top, b.wide, b.tall = getBorderBox(shape, b.border, b.padding)
    b.left  -= (b.border.left*.6)
    b.top   -= (b.border.top*.6)
    b.right  = b.left + b.wide
    b.bottom = b.top + b.tall
    return b
end

function GetPath(shape::Circle)
        c = NQCircle()
        border   = get(shape.border,  Border(0,0,0,0,0,0, "solid",[],[0,0,0,0]))
        c.border = border
        c.wide   = shape.radius*2
        c.tall   = shape.radius*2
        c.radius = shape.radius + (border.width*0.25)
        c.left   = shape.left + c.radius - (border.left*.5)
        c.top    = shape.top  + c.radius - (border.top*.5)
    return c
end
# ======================================================================================#
# Set circle path and fill with color
"""
## setPath(ctx::CairoContext, shape::NQBox)

...


[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
# ======================================================================================#
function setPath(ctx::CairoContext, shape::NQBox)
    if !isnull(shape.border.radius) #(TR + BR + BL + TL) > 0
        radius = get(shape.border.radius,[0,0,0,0])
        TR = radius[1]
        BR = radius[2]
        BL = radius[3]
        TL = radius[4]
              rot   =   1.5707963    # 90 * degrees
          # TODO: see if curveTo() will work to simplify this.
                new_sub_path(ctx);
         		arc(ctx, shape.right - TR, shape.top    + TR, TR,     -rot,   0   );    # topRight
         		arc(ctx, shape.right - BR, shape.bottom - BR, BR,     0,      rot ); # bottomRight
         		arc(ctx, shape.left  + BL, shape.bottom - BL, BL,     rot,    pi  );   # bottomLeft
         		arc(ctx, shape.left  + TL, shape.top    + TL, TL,     pi,     -rot);      # topLeft
       	        close_path(ctx);
    else
        rectangle(ctx, shape.left, shape.top, shape.wide, shape.tall )
    end
end
function setPath(ctx, shape::NQCircle)
        move_to(ctx, shape.left, shape.top)
        arc(ctx, shape.left, shape.top, shape.wide*.5, 0, 2*pi);
end
# ======================================================================================
"""
## setClipPath(ctx::CairoContext, shape::NQCircle)

...

# Examples
```julia-repl
```
[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
function setClipPath(ctx::CairoContext, shape::NQCircle)
    b  = shape.border.top #*.5
        move_to(ctx, shape.left + shape.radius, shape.top)
        arc(ctx, shape.left, shape.top, shape.radius+b, 0, 2*pi);
  return b
end

function setClipPath(ctx::CairoContext, shape::NQBox)
  bw  = shape.border.width*.5
  bh  = shape.border.height*.5
  borderWidth = max(shape.border.left, shape.border.top, shape.border.right,shape.border.bottom)

  if !isnull(shape.border.radius) #(TR + BR + BL + TL) > 0
      radius = get(shape.border.radius,[0,0,0,0])
      TR = radius[1]
      BR = radius[2]
      BL = radius[3]
      TL = radius[4]
            rot   =   1.5707963    # 90 * degrees
        # TODO: see if curveTo() will work to simplify this.
        borderWidth = max(shape.border.left, shape.border.top, shape.border.right,shape.border.bottom)
        line = (borderWidth/2)
        t = shape.top  #- (line - shape.border.top)
        l = shape.left  #- (line - shape.border.left)
        r = shape.right       #(shape.border.right - line)
        b = shape.bottom      #(shape.border.bottom - line)
            new_sub_path(ctx);
              arc(ctx, r - TR, t + TR, TR,     -rot,   0   );    # topRight
              arc(ctx, r - BR, b - BR, BR,     0,      rot ); # bottomRight
              arc(ctx, l + BL, b - BL, BL,     rot,    pi  );   # bottomLeft
              arc(ctx, l + TL, t + TL, TL,     pi,     -rot);      # topLeft
            close_path(ctx);
  else
      rectangle(ctx, shape.left, shape.top, shape.wide, shape.tall )
  end
  return borderWidth
end
# ======================================================================================
"""
## setborderPath(ctx::CairoContext, shape::NQBox)

...

[Source](https://github.com/TravisA9/NaquadahBrowser/blob/39c41cbb1ac28fe94876fe01beaa6e046c8b63d3/src/Graphics/GraphDraw.jl#L54)
"""
function setborderPath(ctx::CairoContext, shape::NQBox)

  # TODO: see if curveTo() will work to simplify this.
  borderWidth = max(shape.border.left,shape.border.top,shape.border.right,shape.border.bottom)
  line = (borderWidth/2)
  t = shape.top - (line - shape.border.top)
  l = shape.left - (line - shape.border.left)
  r = shape.right - (shape.border.right - line)
  b = shape.bottom - (shape.border.bottom - line)

    if !isnull(shape.border.radius) #(TR + BR + BL + TL) > 0
      radius = get(shape.border.radius,[0,0,0,0])
      TR = radius[1]
      BR = radius[2]
      BL = radius[3]
      TL = radius[4]
      rot   =   1.5707963    # 90 * degrees
              new_sub_path(ctx);
                arc(ctx, r - TR, t + TR, TR,     -rot,   0   );    # topRight
                arc(ctx, r - BR, b - BR, BR,     0,      rot ); # bottomRight
                arc(ctx, l + BL, b - BL, BL,     rot,    pi  );   # bottomLeft
                arc(ctx, l + TL, t + TL, TL,     pi,     -rot);      # topLeft
              close_path(ctx);
    else
        rectangle(ctx, l, t, r, b )
    end
end
function setborderPath(ctx::CairoContext, shape::NQCircle)
        move_to(ctx, shape.left + shape.radius, shape.top)
        arc(ctx, shape.left, shape.top, shape.radius, 0, 2*pi);
end

# ======================================================================================
#  This is to tell text_extents() how to measure text
# ======================================================================================
function setTextContext(ctx::CairoContext, node::Text)
    font = node.parent.font
    slant  = fontSlant(font)
    weight = fontWeight(font)
    select_font_face(ctx, font.family, slant, weight);
    set_font_size(ctx, font.size);
end
# ======================================================================================
function GetlastColor(node)
    while !isdefined(node.shape, :color) || length(node.shape.color) < 3
            node = node.parent
    end
    return node.shape.color
end
# ======================================================================================
#
# ======================================================================================
function DrawSelectedText(ctx::CairoContext, nodeList, l,r,t,b, clipPath)
last = length(nodeList)
width,left = 0,0
allSelectedText = ""


    function PaintBox(ctx, color, l,t,r,b)
        setcolor( ctx, color...)
        rectangle(ctx,  l,t,r,b )
        fill(ctx)
    end

offset = 0
    for n in 1:last
        chunkStart, chunkEnd = 0,0
        s = nodeList[n].shape #n.shape
        setTextContext(ctx, nodeList[n]) # this is to tell text_extents() how to measure text

        # TODO: make this work when start and end are on the same line!
        if n == 1 # First selected line!
            offset = 0
            newLeft = 0
            start = l-s.left
            for i in 1:length(s.text)
                extents = text_extents(ctx, s.text[1:i] )[3];
                if extents < start
                    offset = i
                    newLeft = extents
                else
                    break
                end
            end
            allSelectedText *= s.text[offset+1:end] * "\n"
            left, width = s.left+newLeft,  s.width-newLeft
            if newLeft > 0 # how much to redraw before selection start
                color = GetlastColor(nodeList[n].parent) #nodeList[n].parent.shape.color
                if length(color) == 0
                    color = [0,0,0]
                end
                PaintBox(ctx, color, s.left,  s.top, newLeft,  s.height)
            end
        elseif  n == last # Last selected line!
            newRight = 0
            offset = 0
            ending = r-s.left # actual selected width.
            for i in length(s.text):-1:1
                extents = text_extents(ctx, s.text[1:i] )[3];
                if extents > ending
                    offset = i
                    newRight = extents
                else
                    break
                end
            end

            allSelectedText *= s.text[1:offset] * "\n"
            left, width = s.left,  newRight
            if newRight > 0 # how much to redraw after selection end
                #chunkStart, chunkEnd = left+width, s.left+s.width
                color = GetlastColor(nodeList[n].parent) #nodeList[n].parent.shape.color
                PaintBox(ctx, color, left+width,  s.top, s.width-width,  s.height+1)
            end
        else
            allSelectedText *= s.text * "\n"
            left, width = s.left,  s.width+1
        end
clipboard(allSelectedText)

        rectangle(ctx,  clipPath... )
        clip(ctx)
        # if chunkStart == 0 # how much to redraw before/after selection
        #     # this does not take into considderation the posibility that the parent could have an image, gradiant or transparency.
        #     # It may be best to redraw the parent and use this rectangle as a clipping area to reduce the time consumed.
        #     color = nodeList[n].parent.shape.color
        #     println(color)
        #
        #     PaintBox(ctx, color, chunkStart,  s.top, chunkEnd,  s.height+1)
        # end
        PaintBox(ctx, [0.956357, 0.95884, 0.188998], left,  s.top, width,  s.height+1)
        DrawText(ctx, nodeList[n], clipPath)
    end
end
# ======================================================================================
# Draw text.
# ======================================================================================
# -extents[4] is the top of the text
# ======================================================================================
function DrawText(ctx::CairoContext, node, clipPath)
    font = node.parent.font
    shape = node.shape
    #println(font.color)
    left = node.shape.left
    set_antialias(ctx,6)
    slant  = fontSlant(font)
    weight = fontWeight(font)
    select_font_face(ctx, font.family, slant, weight);
    set_font_size(ctx, font.size);

    if !font.flags[TextPath]
        move_to(ctx, shape.left, shape.top + font.size);
        setcolor(ctx, font.color...)
        show_text(ctx, shape.text);

    else  # shaddow
          move_to(ctx, shape.left+4, shape.top + font.size+4);
          text_path(ctx, shape.text);
          setcolor(ctx,  0,0,0,0.4) # fill color
          fill_preserve(ctx);
          setcolor(ctx,  0,0,0,0.1) # outline color
          set_line_width(ctx,  4 ); # 2.56 MyText.lineWidth
          stroke(ctx);

          move_to(ctx, shape.left+4, shape.top + font.size+4);
          text_path(ctx, shape.text);
          setcolor(ctx,  0,0,0,0.2) # fill color
          fill_preserve(ctx);
          setcolor(ctx,  0,0,0,0.1) # outline color
          set_line_width(ctx,  2 ); # 2.56 MyText.lineWidth
          stroke(ctx);

          move_to(ctx, shape.left, shape.top + font.size);
          text_path(ctx, shape.text);
          setcolor(ctx, font.fill...) # fill color
          fill_preserve(ctx);
          setcolor(ctx, font.color...) # outline color
          set_line_width(ctx, font.lineWidth ); # 2.56 MyText.lineWidth
          stroke(ctx);
    end
end
