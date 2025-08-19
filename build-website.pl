#!/usr/bin/perl

# This script reads a .org file and outputs a .html file with the same content translated over.
# The idea is that we just call this repeatedly over all the blog posts we have (and indeed the whole
# website) and thus get a set of nice .html files to put on the internet.

# This part of the script opens the blog post to be read, and grabs the metadata from it. That
# metadata includes the title, date, and tags for the post. So we first open the file.
open(webpage, "<".$blog_name.".org");
open(head, "<head.html");
open(header, "<header.html");
open(aside, "<aside.html");
open(footer, "<footer.html");
open(writepage, ">".$blog_name.".html"); # Output page we will be writing to

$pagetype = 0; # Tells us whether we're looking at a main page, blog post, or otherwise.

# We grab the first lines, which will be of the form "tag : data". We read tag (assuming they come in
# a nice order; I might change that later) and put the data to the side for now.

# First grab the title, date and tags:
$line = <webpage>; ($tag, $title) = split(" : ", $line); chop($title);
$line = <webpage>; ($tag, $subtitle) = split (" : ", $line); chop($subtitle);
$line = <webpage>; ($tag, $date) = split(" : ", $line);
$line = <webpage>; ($tag, $tags) = split(" : ", $line);

# Let's get the preamble of the page down in the head now.
while($line = <head>) {
    $line =~ s/\$title/$title/;
    print writepage $line;
}

if($pagetype == 1){print writepage "<link rel=\"stylesheet\" href=\"css/avernus-main.css\" />"; }

print writepage "</head>\n";
# Can't forget to enter the body of the page.
print writepage "<body>\n";

# Next we add the header and the aside, again by slurping (I think) the relevant files.
while($line = <header>) {
    $line =~ s/\$title/$title/;
    $line =~ s/\$subtitle/$subtitle/;    
    print writepage $line;
}

while($line = <aside>) {
    print writepage $line;
}

print writepage "<main>\n";

# Then go through and replace org headers by html headers.
$list_mode = 0; # Represents what kind of list we're looking at. A 0 means we're not looking at any
    # list, a 1 means we're looking at an unordered list, and a 2 means we're looking
    # at an ordered list.
while ($line = <webpage>){
    chop($line);
    
    while($line =~ s/'/&#8217;/) { } # Replace primes by proper typographical quotes
    while($line =~ s/ \/([^\/]*)\/([^\w])/ <em>$1<\/em>$2/) { } # This replaces slashed text by <em> text
    while($line =~ s/ \*([^\*]*)\* / <strong>$1<\/strong> /) { } # And this *'ed by <strong>
    while($line =~ s/---/&#151;/) { } # Replaces ---'s with em-dashes
    while($line =~ s/--/&#150;/) { } # And this --'s with en-dashes
    
    if ($line !~ /\A-[^-]/ && $list_mode == 1) {print writepage "</ul>\n"; $list_mode = 0;}
    elsif ($line !~ /\A\(\d+\)/ && $list_mode == 2) {print writepage "</ol>\n"; $list_mode = 0;}
    elsif($line =~ /\A-[^-]/ && $list_mode == 0){print writepage "<ul>\n"; $list_mode = 1;}
    elsif($line =~ /\A\(\d+\)/ && $list_mode == 0){print writepage "<ol>\n"; $list_mode =2;}
    
    if ($line =~ /\A\*[^\*]/) { # headings
	($chaff, $header) = split(/\* /, $line);
	print writepage "<h1>$header</h1>\n";
    }
    elsif ($line =~ /\A\*\*[^\*]/) { # subheadings
	($chaff, $header) = split(/\*\* /, $line);
	print writepage "<h2>$header</h2>\n";
    }
    elsif ($line =~ /\A\*\*\*/) { # subsubheadings
	($chaff, $header) = split(/\*\*\* /, $line);
	print writepage "<h3>$header</h3>\n";
    }
    elsif ($line =~ /\A-[^-]/ && $list_mode == 1){ # unordered lists
	$line =~ s/-/<li>/;
	print writepage $line."</li>\n";
    }
    elsif ($line =~ /\A\(\d+\)/ && $list_mode == 2){ # ordered lists
	$line =~ s/\(\d+\)/<li>/;
	print writepage $line."</li>\n";
    }
    elsif ($line =~ /^$/){ } #ie. the empty string	
    else { # everything else is probably a paragraph!
	print writepage "<p>$line</p>\n"; # can't believe perl lets me get away with all those regexps
    }
}
close(webpage);

# How would we like to deal with unordered and ordered lists? Well, it would make sense to keep track,
# line by line, of whether we're looking at a list or not. We start off not being in such a state.
# When we see our first -, we know we've started an unordered list, so write in a <ul> and replace the
# - with a <li>. When we reach a line that doesn't start with a -, we leave the list mode, and
# close the <ul> tag. Do something similar for ordered lists.
# That ought to do the trick.

print writepage "</main>\n";

# Finally, add the footer to the page, in the same manner as the header and aside.

$date =  strftime "%d-%m-%Y", localtime time; # For the footer of the blog page
while($line = <footer>) {
    $line =~ s/\$date/$date/;    
    print writepage $line;
}

print writepage "</body>\n</html>";


