using ReadHFCS

# Preliminaries
identifier_ranges = (:year => [2014, 2017, 2021], :imputation => 1:5)
datadir = joinpath(pwd(), "..", "..", "..", "Datos", "HFCS")

# Read HFCS data (household-level; nt = years per model period for bequest/gift windows)
hfcs_hh = read_hfcs(datadir, identifier_ranges)
filter!(row -> row.pais=="FR", hfcs_hh)