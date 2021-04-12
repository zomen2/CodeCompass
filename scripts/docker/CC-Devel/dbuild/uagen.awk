BEGIN {
    if (length(priority) == 0)
        priority = "50"

    print "#!/usr/bin/env bash"
    print ""
    print "function register_alternative {"

    print "  update-alternatives \\"
}
{
    full_name_of_target = $1
    full_name_of_symlink = full_name_of_target
    sub("-[0-9]+", "", full_name_of_symlink)
    binary_name = full_name_of_symlink
    sub("/.+/", "", binary_name)
    if (NR == 1) {
        print "    --install " full_name_of_symlink " " binary_name " " full_name_of_target " " priority " \\"
    }
    if (NR > 1) {
	
        print "    --slave " full_name_of_symlink " " binary_name " " full_name_of_target " \\"
    }
}
END {
    print "  && echo Registration successfully performed."
    print "}"
    print ""
    print "register_alternative"
}
