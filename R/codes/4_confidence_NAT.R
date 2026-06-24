rm(list=ls())
library(terra)


tiles <- list.files("data/confidence_NAT/", pattern = "\\.tif$", full.names = TRUE)
conf_nat <- vrt(tiles)

# Vérif
conf_nat

# Sauvegarder en un seul raster (va prendre du temps)
writeRaster(conf_nat, "data/confidence_NAT/CDL_conf_2012_national_merged.tif", 
            overwrite = TRUE, datatype = "INT1U")

#check alignment
cdl_nat  <- rast("data/2012_30m_cdls/2012_30m_cdls.tif")
conf_nat <- rast("data/confidence_NAT/CDL_conf_2012_national_merged.tif")

res(cdl_nat)
res(conf_nat)

origin(cdl_nat)
origin(conf_nat)

crs(cdl_nat) == crs(conf_nat)

#but
compareGeom(cdl_nat, conf_nat, stopOnError = F, messages = T)
#Only difference is the extent:
ext(cdl_nat)
ext(conf_nat)

# cdl is a subset of conf
# Hence, we just recrop (we loose some pixel but they weren't used anyway
# it ensures perfect alignment)
conf_nat_aligned <- crop(conf_nat, ext(cdl_nat))
writeRaster(conf_nat_aligned, "data/confidence_NAT/CDL_conf_2012_national_aligned.tif",
            overwrite = TRUE, datatype = "INT1U")
