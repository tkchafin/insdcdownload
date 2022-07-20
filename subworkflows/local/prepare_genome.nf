//
// Uncompress and prepare reference genome files
//

include { BWAMEM2_INDEX           } from '../../modules/nf-core/modules/bwamem2/index/main'
include { GUNZIP                  } from '../../modules/nf-core/modules/gunzip/main'
include { MINIMAP2_INDEX          } from '../../modules/nf-core/modules/minimap2/index/main'
include { REMOVE_MASKING          } from '../../modules/local/remove_masking'
include { SAMTOOLS_FAIDX          } from '../../modules/nf-core/modules/samtools/faidx/main'
include { SAMTOOLS_DICT           } from '../../modules/nf-core/modules/samtools/dict/main'


workflow PREPARE_GENOME {

    main:
    ch_versions = Channel.empty()

    // Uncompress genome fasta file if required
    if (params.fasta.endsWith('.gz')) {
        ch_fasta    = GUNZIP ( [ [:], params.fasta ] ).gunzip
        ch_versions = ch_versions.mix(GUNZIP.out.versions)
    } else {
        ch_fasta = [ [:], file(params.fasta) ]
    }

    // Unmask genome fasta
    REMOVE_MASKING ( ch_fasta )
    ch_versions = ch_versions.mix(REMOVE_MASKING.out.versions)

    // Generate BWA index
    ch_bwamem2_index  = BWAMEM2_INDEX (REMOVE_MASKING.out.fasta).index
    ch_versions       = ch_versions.mix(BWAMEM2_INDEX.out.versions)

    // Generate Minimap2 index
    ch_minimap2_index = MINIMAP2_INDEX (REMOVE_MASKING.out.fasta).index
    ch_versions       = ch_versions.mix(MINIMAP2_INDEX.out.versions)

    // Generate Samtools index
    ch_samtools_faidx = SAMTOOLS_FAIDX (REMOVE_MASKING.out.fasta).fai
    ch_versions       = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)

    // Generate Samtools dictionary
    ch_samtools_dict  = SAMTOOLS_DICT (REMOVE_MASKING.out.fasta).dict
    ch_versions       = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)


    emit:
    fasta    = REMOVE_MASKING.out.fasta  // path: genome.unmasked.fasta
    bwaidx   = ch_bwamem2_index          // path: bwamem2/index/
    minidx   = ch_minimap2_index         // path: minimap2/index/
    faidx    = ch_samtools_faidx         // path: samtools/faidx/
    dict     = ch_samtools_dict          // path: samtools/dict/

    versions = ch_versions.ifEmpty(null) // channel: [ versions.yml ]
}
