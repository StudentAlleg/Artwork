-- NOTE: In order to be called from elsewhere, functions and variables must be returned at the end of this file.

-- VARIABLES. 
--colors
color = {}
color.white = Color.Create(1,1,1,0.75)
color.dark = Color.Create(0,0,0,0.5)
color.transparent = Color.Create(0,0,0,0)
--fonts
font = {}
font.p = Font.Create("Trebuchet MS", 18)
font.pbold = Font.Create("Trebuchet MS", 18, {Bold=true})
font.h1 = Font.Create("Trebuchet MS", 25, {Bold=true})
font.h2 = Font.Create("Trebuchet MS", 23, {Italic=true, Bold=true})
font.h3 = Font.Create("Trebuchet MS", 21, {Bold=true})
font.h4 = Font.Create("Trebuchet MS", 19, {Bold=true})

-- FUNCTIONS
-- example: Global.create_backgroundpane(800,600,{src=Image.File("/global/images/backgroundpane.png"), partsize=50, color=button_normal_color})
-- example: Global.create_backgroundpane(300,150) 
function create_backgroundpane(width, height, opt)
	opt = opt or {}
	imagesrc = opt.src or Image.File("/global/images/backgroundpane.png") --the image must be at least 3x partsize in height and width.
	paintcolor = opt.color or white
	imagesrc = Image.Multiply(imagesrc,paintcolor)
	srcimgw = Point.X(Image.Size(imagesrc))
	srcimgh = Point.Y(Image.Size(imagesrc))
	partsize = opt.partsize or 50 --the partsize is one number. parts must be square.
	dblsize = Number.Multiply(partsize,2) -- just convenient because it's used a lot
	stretchfactorw = (width-dblsize)/partsize+0.001 -- calculate how much we need to stretch the parts 
	stretchfactorh = (height-dblsize)/partsize+0.001
	--[[
	we're cutting the image up in 9 sections as follows
	tlc		tb		trc   
	lb		mid 	rb
	blc		bb		brc
 	]]
	-- toprow
	tlc = Image.Cut(imagesrc, Rect.Create(0,0,partsize,partsize)) -- top left corner
	tb = Image.Cut(imagesrc, Rect.Create(partsize, 0, dblsize, partsize)) -- top border
	-- we stretch the top border part
	tb = Image.Scale(tb, Point.Create(stretchfactorw,1))
	trc = Image.Cut(imagesrc, Rect.Create(Number.Subtract(srcimgw, partsize),0,srcimgw,partsize)) -- top right corner
	-- mid row
	lb = Image.Cut(imagesrc, Rect.Create(0, partsize, partsize, dblsize)) -- left border
	mid = Image.Cut(imagesrc, Rect.Create(partsize, partsize, dblsize, dblsize)) -- middle 
	-- stretch the middle part
	mid = Image.Scale(mid, Point.Create(stretchfactorw,1))
	rb = Image.Cut(imagesrc, Rect.Create(Number.Subtract(srcimgw, partsize), partsize, srcimgw, dblsize)) -- right border
	-- combine middle images in a single middle row.
	row = Image.Group({
		Image.Translate(lb, Point.Create(0,0)),
		Image.Translate(mid, Point.Create(partsize,0)),
		Image.Translate(rb, Point.Create(Number.Subtract(width,partsize),0)),
		})
	--stretch the completed middle row vertically
	row = Image.Scale(row, Point.Create(1, stretchfactorh)) 
	-- bottom row
	blc = Image.Cut(imagesrc, Rect.Create(0, Number.Subtract(srcimgh, partsize),partsize,srcimgh)) -- bottom left corner
	bb = Image.Cut(imagesrc, Rect.Create(partsize, Number.Subtract(srcimgh, partsize), dblsize, srcimgh)) 
	bb = Image.Scale(bb, Point.Create(stretchfactorw,1))
	brc = Image.Cut(imagesrc, Rect.Create(Number.Subtract(srcimgw, partsize), Number.Subtract(srcimgh, partsize),srcimgw,srcimgh)) --bottom right corner
	-- position all parts relative to top left corner
	parts = {}
	parts[#parts+1] = tlc
	parts[#parts+1] = Image.Translate(tb, Point.Create(partsize,0))
	parts[#parts+1] = Image.Translate(trc, Point.Create(Number.Subtract(width,partsize),0))
	parts[#parts+1] = Image.Translate(row, Point.Create(0, partsize))
	parts[#parts+1] = Image.Translate(blc, Point.Create(0, Number.Subtract(height, partsize)))
	parts[#parts+1] = Image.Translate(bb, Point.Create(partsize, Number.Subtract(height, partsize)))
	parts[#parts+1] = Image.Translate(brc, Point.Create(Number.Subtract(width,partsize), Number.Subtract(height, partsize)))

	return Image.Group(parts)
end

function create_box(w, h, opt)
	--example create_box(300,700,{border_width=5, border_color=Color.Create(1,1,0), background_color=Color.Create(1,0,0)})
	-- or create_box(300,700)
	opt = opt or {}
	borderwidth = opt.border_width or 1
	bordercolor = opt.border_color or color.white
	backgroundcolor = opt.background_color or color.transparent
	yoffset = Number.Multiply(borderwidth, 2)
	boxarea = Image.Extent(Point.Create(w, h), backgroundcolor)
	borderhoriz = Image.Extent(Point.Create(w, borderwidth), bordercolor)
	bordervert = Image.Extent(Point.Create(borderwidth,Number.Subtract(h, yoffset)), bordercolor)
	box = Image.Group({		
		boxarea,
		borderhoriz,
		Image.Translate(bordervert,Point.Create(0,borderwidth)),
		Image.Translate(bordervert,Point.Create(Number.Subtract(w,borderwidth), borderwidth)),
		Image.Translate(borderhoriz, Point.Create(0, Number.Subtract(h, borderwidth))),

		})
	return box
end

-- this function allows you to use degrees rather than radials to rotate images.
function rotate_image_degree(image, degree)
	fraction = Number.Divide(degree,360)
	tau = 6.283185307179586476925286766559
	radialrotation = Number.Multiply(fraction,tau)
	return Image.Rotate(image,radialrotation)
end	

function list_sum(lst)
	sum = 0
	lst = lst
	for i,val in ipairs(lst) do
		sum = Number.Add(sum,val)
	end	
	return sum
end

function list_concat(lst, separator)
--	n = 0
--	for i in pairs(lst) do n=n+1 end
	sp = separator or ""
	ln = ""
	if space == true then sp = " " end
	for i,val in ipairs(lst) do
		if i>1 then ln=String.Concat(ln,sp) end
		ln = String.Concat(ln,val)
	end	
	return ln
end

----------- scrollbar code -----------------


-- this function is dimension-agnostic:
-- feed it an image and it will figure out wether the scrollbar is supposed to be horizontal or vertical
-- scale_scrollbarpart([image file], [integer, desired length or width], [integer, ends of the bar that should not be scaled])
-- example: scale_scrollbarpart(Image.File("path/image.png"), 800, 10)

function scale_scrollbarpart(image, i_dimension, i_partsize)
	origwidth = Point.X(Image.Size(image))
	origheight = Point.Y(Image.Size(image))
	scalefactor = (i_dimension-(2*i_partsize))/i_partsize-0.001 -- calculate how much we need to stretch the middle part, the 2's are for 1px overlaps on both ends

	function horizontal_scrollbar()
			leftpart = Image.Cut(image, Rect.Create(0,0,i_partsize,origheight))
			midpart = Image.Scale(Image.Cut(image, Rect.Create(i_partsize,0, i_partsize*2, origheight)),Point.Create(scalefactor,1))
			rightpart = Image.Cut(image, Rect.Create(origwidth-i_partsize,0,origwidth,origheight))
		return Image.Group({
				leftpart,
				Image.Translate(midpart,Point.Create(i_partsize,0)),
				Image.Translate(rightpart, Point.Create(i_dimension-i_partsize,0))
			})
	end
	function vertical_scrollbar()
		toppart = Image.Cut(image, Rect.Create(0,0, origwidth, i_partsize))
		midpart = Image.Scale(Image.Cut(image, Rect.Create(0, i_partsize, origwidth, i_partsize*2)),Point.Create(1, scalefactor))
		bottompart = Image.Cut(image, Rect.Create(0, origheight-i_partsize,origwidth, origheight))
		return Image.Group({
			toppart,
			Image.Translate(midpart,Point.Create(0, i_partsize)),
			Image.Translate(bottompart, Point.Create(0, Point.Y(Image.Size(midpart))+i_partsize))
			})
	end

	scrollbarpart = Image.Switch(
		Number.Min(Number.Max(0,origwidth-origheight),1),
		{
		[0]=vertical_scrollbar(),
		[1]=horizontal_scrollbar()
		})

	return scrollbarpart
end


function create_vertical_scrollbar(position_fraction, height, grip_height, paint)
	grip_original = Image.Multiply(Image.File("global/images/scrollbargrip_roundedline.png"), paint)
	staticEndSize = 14 -- in px
	grip = scale_scrollbarpart(grip_original, grip_height, staticEndSize)
	
	scrollbarbg_original = Image.Multiply(Image.File("global/images/scrollbar_bg_thin.png"), paint)
	scrollbarbg = scale_scrollbarpart(scrollbarbg_original, height, staticEndSize)
	scrollbar_width = Point.X(Image.Size(scrollbarbg))
	
 	scrollbar_translation_per_fraction = Number.Subtract(height, grip_height)
	fraction_per_scrollbar_translation = Number.Divide(1, scrollbar_translation_per_fraction)

	grip_translation = Point.Create(0, Number.Add(0, Number.Multiply(position_fraction, scrollbar_translation_per_fraction)))

	grip_translated = Image.MouseEvent(Image.Translate(grip, grip_translation))

	Event.OnEvent(position_fraction, Event.GetPoint(grip_translated, "drag"), function (dragged)
		return Number.Clamp(0, 1, Number.Add(position_fraction, Number.Multiply(fraction_per_scrollbar_translation, Point.Y(dragged))))
	end)

	return {
		width=scrollbar_width,
		image=Image.Group({
			scrollbarbg,
			grip_translated,
		})
	}
end

function create_vertical_scrolling_container(target_image, container_size, paint)
	-- retrieve the dimensions of the scrolling window
	container_width = Point.X(container_size)
	container_height = Point.Y(container_size)
	-- retrieve dimensions of the image to be placed inside
	target_size = Image.Size(target_image)
	target_height = Point.Y(target_size)

	position_fraction = Number.CreateEventSink(0)

	grip_height = Number.Max(
		50,
		Number.Min( 
			(container_height/target_height)*container_height,
			container_height
		)
	)

	scrollbar = create_vertical_scrollbar(
		position_fraction, 
		container_height, 
		grip_height,
		paint
	)
	
	cut_width = Number.Subtract(container_width, scrollbar.width)

	offset_x = 0

	offset_y = Number.Multiply(position_fraction, Number.Subtract(target_height, container_height))

	scroll_window = Image.Group({
		Image.Cut(target_image, Rect.Create(offset_x, offset_y, cut_width, Number.Add(offset_y, container_height))),
		Image.Translate(scrollbar.image, Point.Create(cut_width, 0))
	})
	return scroll_window

end

return {
	-- other
	testingstring = testingstring,
	--global colors
	color = color,
	-- global fonts
	font = font,
	-- global functions
	list_sum = list_sum,
	list_concat = list_concat,
	create_box = create_box,
	create_backgroundpane = create_backgroundpane,
	create_vertical_scrolling_container=create_vertical_scrolling_container,
	rotate_image_degree = rotate_image_degree,
}
