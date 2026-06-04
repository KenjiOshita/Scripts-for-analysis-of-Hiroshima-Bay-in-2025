library(dplyr)
library(readr)
library(tidyr)
# ------------------------------------------------------------------------------
# 1. Data import
# asv_counts.tsv: Skip the comment on the first line
otu_row <- read_tsv("asv_counts.tsv", skip = 1) 
# taxonomy.tsv
taxo_row <- read_tsv("taxonomy.tsv")
# convert.txt: As there is no header, load it with a name
asv_row <- read_table("convert.txt", col_names = c("Feature_ID", "ASV_Name"))
# ------------------------------------------------------------------------------
# 2. Replacement of ASV IDs
# Replacement in asv_counts.tsv
otu_replaced <- otu_row %>%
  # Join using "OTU ID" and "Feature_ID" as keys
  left_join(asv_row, by = c("#OTU ID" = "Feature_ID")) %>%
  # Replace with ASV_Name if it exists, otherwise keep the original ID
  mutate(`#OTU ID` = coalesce(ASV_Name, `#OTU ID`)) %>%
  # Remove the ASV_Name column as it is no longer needed
  select(-ASV_Name)
# Replacement in taxonomy.tsv
taxo_replaced <- taxo_row %>%
  # Join using "Feature ID" and "Feature_ID" as keys
  left_join(asv_row, by = c("Feature ID" = "Feature_ID")) %>%
  mutate(`Feature ID` = coalesce(ASV_Name, `Feature ID`)) %>%
  select(-ASV_Name) %>%
  # Split the Taxon column into 7 hierarchical columns separated by ";"
  separate(
    col = Taxon, 
    into = c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species"), 
    sep = ";\\s*",    # Split by ";" or ";" followed by a space
    fill = "right",   # Fill missing levels (right side) with NA
    extra = "warn"    # Warn if more than 7 levels are found
  )
# ------------------------------------------------------------------------------
# 3. Export each as CSV
write_csv(otu_replaced, "asv_counts_converted.csv")
write_csv(taxo_replaced, "taxonomy_converted.csv")