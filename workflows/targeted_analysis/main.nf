/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Loaded from modules/
//

include { BWA_ALIGN_READS } from "../../subworkflows/align_bwa"
include { GATK_BEST_PRACTICES } from "../../subworkflows/gatk_best_practices"
include { VCF_FILTER_AND_DECOMPOSE } from "../../subworkflows/vcf_filter_and_decompose"
include { VEP_ANNOTATE } from "../../subworkflows/vep_annotation"
include { AUTOSOLVE_MULTISAMPLE } from "../../subworkflows/autosolve/autosolve_multisample"
include { BAM_QC } from "../../subworkflows/bam_qc"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline
//
workflow TARGETED_ANALYSIS {
    
    take:
    reads
    ref_genome
    ref_genome_index
    known_snps_dbsnp
    known_indels
    known_snps_dbsnp_index
    known_indels_index
    target_bed
    target_bed_covered
    vep_cache
    vep_plugins
    vcf_to_tsv_script
    mane_transcript
    autosolve_script
    panel_monoallelic
    panel_biallelic
    clingen
    mutation_spectrum
    refgene_track
    ch_versions

    main:

    ch_versions = Channel.empty()
    
    BWA_ALIGN_READS(
        reads,
        ref_genome,
        ref_genome_index
    )
    ch_versions = ch_versions.mix(BWA_ALIGN_READS.out.versions)

    ch_aligned_bam = BWA_ALIGN_READS.out.aligned_bam
    GATK_BEST_PRACTICES(
        ch_aligned_bam,
        ref_genome,
        ref_genome_index,
        known_snps_dbsnp,
        known_indels,
        known_snps_dbsnp_index,
        known_indels_index,
        target_bed
    )
    ch_versions = ch_versions.mix(GATK_BEST_PRACTICES.out.versions)

    ch_raw_vcf = GATK_BEST_PRACTICES.out.raw_vcf
    VCF_FILTER_AND_DECOMPOSE(
        ch_raw_vcf,
        ref_genome,
        ref_genome_index
    )

    ch_versions = ch_versions.mix(VCF_FILTER_AND_DECOMPOSE.out.versions)

    ch_decom_norm_vcf = VCF_FILTER_AND_DECOMPOSE.out.decom_norm_vcf
    VEP_ANNOTATE(
        ch_decom_norm_vcf,
        vep_cache,
        vep_plugins,
        vcf_to_tsv_script,
        mane_transcript
    )
    ch_versions = ch_versions.mix(VEP_ANNOTATE.out.versions)

    ch_vep_tsv_filtered = VEP_ANNOTATE.out.vep_tsv_filtered.groupTuple()
    AUTOSOLVE_MULTISAMPLE(
        ch_vep_tsv_filtered,
        autosolve_script,
        clingen,
        panel_monoallelic,
        panel_biallelic,
        mutation_spectrum
    )

    ch_vep_tsv_filtered = GATK_BEST_PRACTICES.out.bqsr_bam
    BAM_QC(
        ch_vep_tsv_filtered,
        target_bed_covered,
        ref_genome,
        ref_genome_index,
        refgene_track
    )
    ch_versions = ch_versions.mix(BAM_QC.out.versions)

    emit:
        //BWA_ALIGN_READS.out.aligned_bam
        //GATK_BEST_PRACTICES.out.marked_dup_bam
        GATK_BEST_PRACTICES.out.bqsr_recal_table
        GATK_BEST_PRACTICES.out.bqsr_bam
        GATK_BEST_PRACTICES.out.gvcf_file
        GATK_BEST_PRACTICES.out.gvcf_index
        GATK_BEST_PRACTICES.out.raw_vcf
        VCF_FILTER_AND_DECOMPOSE.out.filtered_vcfs
        VCF_FILTER_AND_DECOMPOSE.out.decom_norm_vcf
        VEP_ANNOTATE.out.annotated_vcf
        VEP_ANNOTATE.out.vep_tsv
        VEP_ANNOTATE.out.vep_tsv_filtered
        VEP_ANNOTATE.out.vep_tsv_filtered_highqual
        AUTOSOLVE_MULTISAMPLE.out.autosolve_tsv
        BAM_QC.out.qualimap_stats
        BAM_QC.out.depth_of_coverage_stats
        versions = ch_versions
}
