#===========================================================================#
#=									   =#
#   Filename:	    col_filter.sh
#   Version:	    1.0
#=									   =#
#   Description:    print given columns based on header from dataset
#		    col_filter.sh "<colN>" <file>
#
#=  Author:	    0cb - Christian Bowman				   =#
#   Creation:	    2021-01-22
#   Updated:	    
#=									   =#
#===========================================================================#

#sauce: https://stackoverflow.com/questions/36471244/print-certains-columns-by-header-name-with-spaces-on-it-awk-sed
# NOTE: HURDUR SYNTAX 'BEGIN must be on same line as awk command <22-01-21, 0cb> #

# send defined vars to an array for awk to use

#awk -v cols="FeretX1,FeretY1,FeretX2,FeretY2,Feret,BrdthX1,BrdthY1,BrdthX2,BrdthY2,Breadth" 'BEGIN {

awk -v cols="$1" 'BEGIN {
	FS=OFS=",";
	nc=split(cols, a, ",")
    }
    NR==1 {
       for (i=1; i<=NF; i++)
	  hdr[$i]=i
    }
    {
       for (i=1; i<=nc; i++)
          if (a[i] in hdr)
	     printf "%s%s", $hdr[a[i]], (i<nc?OFS:ORS)
    }' "$2" > $2-filtered.csv
