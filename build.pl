#!/usr/bin/perl
use POSIX;

# My most devilish idea. Here we first find all the .org files in the blog-posts directory, then
# load the build-website.pl file into a string. The devilish part is that, instead of just calling
# build-website with some argument, we go through and substitute the current org file's name
# into all occurrences in the build-website script. Then we evaluate that substituted script. Wow.

opendir(mainpages, "."), "." or die;
@mainfiles = readdir mainpages;
closedir(mainpages);

foreach $file(@mainfiles){
   if($file =~ /.*\.org$/) { # a hit!
	$final_script = ""; # The string we'll be storing our program in
	open(script, "build-website.pl") or die "Made a typo";
	substr($file, -4) = ""; # Should be safe; we know our files end ".org"
	while ($line = <script>){
	    # Substitute in our current file's name, and add that line to the $final_script string.
	    $line =~ s/"\.\$blog_name\."/$file/;
	    $line =~ s/\$pagetype \= 0/\$pagetype \= 1/; # This feels like cheating.
	    $final_script = $final_script . $line;
	}
	# Finally, evaluate our program.
	eval($final_script);
	close script;
   };
}

# Since we'll be adding the blog information to blog.html, we'll need to open the page first.
open(mainblogpage, ">blog.html") or die "No main blog page found!\n";

open(head, "<head.html");
while($line = <head>){
    $line =~ s/\$title/Hera\'s Blog/;
    print mainblogpage $line;    
}
print writepage "</head>\n"; close(head);

open(header, "<header.html");
while($line = <header>){
    $line =~ s/\$title/Castles In The Sky/;
    $line =~ s/\$subtitle/A blog about theoretical computer science/;    
    print mainblogpage $line;    
}
close(header);

open(aside, "<aside.html");
while($line = <aside>){
    print mainblogpage $line;
}
close(aside);

print mainblogpage "<main>\n";
print mainblogpage "<p>Here&#8217;s a blog of things I&#8217;ve found interesting in computer science. I&#8217;ve tried to write this blog as if it were for my younger undergraduate self, perhaps some time between first arriving at university and the end of second year. That&#8217;s just a rough guide, though! Hopefully some of it is interesting.</p>\n
<h1>Posts</h1>\n
<p> Here&#8217;s what I've been up to. Click the titles of the posts to go to their respective pages.</p>\n";

# First, find the relevant files; we only want the .org files, since we'll be turning them into html.
opendir(blogs, "blog-posts"), "." or die "No blog posts!\n";
@files = readdir blogs;
closedir blogs;

# Now filter through for .org files, and then call build-website.pl when we find one.
foreach $file (@files){
    if($file =~ /.*\.org$/) { # a hit!
	$final_script = ""; # The string we'll be storing our program in
	open(script, "build-website.pl") or die "Made a typo";
	substr($file, -4) = ""; # Should be safe; we know our files end ".org"
	while ($line = <script>){
	    # Substitute in our current file's name, and add that line to the $final_script string.
	    $line =~ s/"\.\$blog_name\."/blog-posts\/$file/;
	    $final_script = $final_script . $line;
	}
	# Finally, evaluate our program.
	eval($final_script);
	close script;

	# Gather data for the blog.
	open(blog, "<blog-posts/".$file.".org") or die "test.pl can't find a blog post!";
	$line = <blog>; ($tag, $title) = split(" : ", $line); chop($title);
	$line = <blog>; ($tag, $subtitle) = split (" : ", $line); chop($subtitle);
	$line = <blog>; ($tag, $date) = split(" : ", $line); chop($date);
	$line = <blog>; ($tag, $tags) = split(" : ", $line);
	$line = <blog>; $line = <blog>; # Get the first line of the blog
	close(blog);

	@timings = split /-/, $date;$newdate = @timings[2]."-".@timings[1]."-".@timings[0];
	$filenames{$title} = $file;
	$titles{$title} = $title;
	$subtitles{$title} = $subtitle;
	$newdates{$title} = $newdate;
	$dates{$title} = $date;
	$tagses{$title} = $tags;
	$lines{$title} = $line;
    };
}

sub bydate{
    $newdates{$a} cmp $newdates{$b};
}
foreach $post (reverse sort bydate keys %newdates){
    print mainblogpage "<article>\n<hgroup>";
    print mainblogpage "<h1><a class=\"title-link\" href=\"blog-posts/".$filenames{$post}.".html\">".$titles{$post}."</a></h1>\n";
    print mainblogpage "<h2><a class=\"title-link\" href=\"blog-posts/".$filenames{$post}.".html\">".$subtitles{$post}."</a></h2>\n";
    print mainblogpage "<time>".$dates{$post}."</time>\n";
    print mainblogpage "</hgroup>\n";
    print mainblogpage "<p>".$lines{$post}."<\p>\n";
    print mainblogpage "</article>\n";
}

print mainblogpage "</main>\n";

$date =  strftime "%d-%m-%Y", localtime time; # For the footer of the blog page
open(footer, "<footer.html");
while($line = <footer>) {
    $line =~ s/\$date/$date/;    
    print mainblogpage $line;
}
