#======================================================================================#
# drawAllElements()
# DrawPage()
#======================================================================================#

# xmin left   ymin top   width width   height height box area
# ======================================================================================
# Draw Elements from Layout Tree
# CALLED FROM: DrawPage(document) -->  Below
# ======================================================================================
#  drawAllElements(context,document.node[1]) # document.DOM
function drawAllElements(context,node)

    nodes = node.node

            for n in nodes
                     # This will limit which nodes are drawn but clipping still needs to be done...
                     # it may be possible to do so with draw_surface-type functions
                     # https://www.cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-t
                    if n.box.top < (node.area.height + node.box.top) ||
                       n.box.left < (node.area.width + node.box.width)
                       # IN: Paint.jl
                        DrawNode(context,n)
                        drawAllElements(context,n)
                    end
            # Flop
            #if node.flags[OverflowClip] == true;    reset_clip(context);    end
            end
end
# ======================================================================================
# Fetch the page and build the DOM and Layout Tree, then render
# CALLED FROM:
# ======================================================================================
function DrawPage(document)
    # println("Draw Page...")
    canvas = document.ui.canvas

# https://developer.gnome.org/gtkmm-tutorial/stable/chapter-drawingarea.html.en
  @guarded draw(canvas) do widget

        context = getgc(canvas)
        document.events = EventTypes()
        node = document.node[1]
        p = Point(0,0)
        #node.box.width, node.box.height = width(context), height(context) # content
        node.area.width, node.area.height = width(context), height(context)
        # LayoutInner(node,node.DOM ,0,0,width(context),height(context))
        LayoutInner(node,node.DOM,p)

            # OnInitialize: 0.649740 seconds (359.77 k allocations: 15.420 MB, 1.01% gc time)
            # OnResize:     0.005325 seconds (6.80 k allocations: 339.750 KB)

            @time    traceElementTree(document,node, node.DOM)

            # Erase all previous
            rectangle(context,  0,  0,  node.box.width, node.box.height )
            set_source_rgb(context, 1,1,1);
            fill(context);
            # Draw all
            set_line_width(context, 1);
            rectangle(context, (node.box.left),  (node.box.top),
                 node.box.width, node.box.height )
            set_source_rgb(context, 0.95,0.95,0.95); stroke(context);

            # 0.621208 seconds (444.03 k allocations: 19.054 MB, 1.00% gc time)
            print("drawAllElements: ")
           drawAllElements(context,node)


                # corner thingie
                select_font_face(context, "Sans", Cairo.FONT_SLANT_NORMAL, Cairo.FONT_WEIGHT_NORMAL);
                set_font_size(context, 12.0);
                set_source_rgba(context, 0,0,0,0.5);
                rectangle(context, 0,  height(context)-20,
                  node.box.width/4,  20 )
                fill(context)

                move_to(context,010,height(context)-5);
                set_source_rgb(context, 1,1,1);
                show_text(context,Libc.strftime(time()));

stroke(context)

end
   show(canvas)
    AttatchEvents(document)

end
