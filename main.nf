#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*params.reads   = "*_R{1,2}.{fq,fastq}.gz"
params.ref     = "/prism_data5/share/GATK_Bundle/hg38/newref/Homo_sapiens_assembly38.fasta"
params.ref_fai = "/prism_data5/share/GATK_Bundle/hg38/newref/Homo_sapiens_assembly38.fasta.fai"
*/
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ref_fa = file(params.ref)
ref_fai = file(params.ref_fai)
known_snps_dbsnp = file(params.known_snps_dbsnp)
known_snps_dbsnp_index = file(params.known_snps_dbsnp + '.tbi')
known_indels_dbsnp = file(params.known_indels)
known_indels_dbsnp_index = file(params.known_indels + '.tbi')
target_bed = file(params.target_bed)
target_bed_covered = file(params.target_bed_covered)
vep_cache = file(params.vep_cache_dir)
vep_plugins = file(params.vep_plugin_dir)
vcf_to_tsv_script=file(params.vcf_to_tsv)
mane_transcript=file(params.mane_transcript)
clingen = file(params.clingen)
mutation_spectrum = file(params.mutation_spectrum)
autosolve_script = file(params.autosolve_script)
panel_monoallelic = file(params.panel_monoallelic)
panel_biallelic = file(params.panel_biallelic)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Get sample id
//
def getLibraryId( file ) {
        file.split(/\//)[-1].split(/_/)[0]
}

include {TARGETED_ANALYSIS} from "./workflows/targeted_analysis"

workflow PRISM_TARGETED_ANALYSIS {

    main:

    ch_versions = Channel.empty()

    Channel
        .fromFilePairs( params.reads, flat: true )
        .map { prefix, file1, file2 -> tuple(getLibraryId(prefix), file1, file2) }
        .groupTuple()
        .set {reads}

    TARGETED_ANALYSIS(
        reads, 
        ref_fa, 
        ref_fai,
        known_snps_dbsnp,
        known_indels_dbsnp,
        known_snps_dbsnp_index,
        known_indels_dbsnp_index,
        target_bed,
        vep_cache,
        vep_plugins,
        vcf_to_tsv_script,
        mane_transcript,
        autosolve_script,
        panel_monoallelic,
        panel_biallelic,
        clingen,
        mutation_spectrum,
        ch_versions
    )
    ch_versions = ch_versions.mix(TARGETED_ANALYSIS.out.versions)
}

workflow {

    main: 
    PRISM_TARGETED_ANALYSIS()
}



    
