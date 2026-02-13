//
//  ComorbityDomain.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//

enum ComorbidityCategory: String {
    case cardiovascular
    case neurological
    case genetical
    case infectious
    case oncological
    case andrological
    case gynecological
    case genitourinary
    case muskuloeskeletical
    case imunological
    case hematological
    case gastrointestinal
    case endocrinal
    case respiratory
    case infant
    case pregnant
    
}

enum CardioComorbidityCode: String, CaseIterable, DomainCode {
    case has
    case valvopathy
    case iam
    case chf
    case arrhythmia
    case cad
    case pacemaker
    case stent
    case custom

    var displayName: String {
        switch self {
        case .has: return "Hipertensão arterial sistêmica"
        case .valvopathy: return "Valvopatias"
        case .iam: return "IAM prévio"
        case .chf: return "Insuficiência cardíaca"
        case .arrhythmia: return "Arritmias"
        case .cad: return "Doença coronariana"
        case .pacemaker: return "Marcapasso / dispositivo"
        case .stent: return "Stent coronariano"
        case .custom: return "Outros"
        }
    }

    static var customCase: CardioComorbidityCode { .custom }
}

enum NeuroComorbidityCode: String, CaseIterable, DomainCode {
    case stroke
        case transientIschemicAttack
        case epilepsy
        case parkinsonsDisease
        case multipleSclerosis
        case alzheimersDisease
        case guillainBarreSyndrome
        case cerebralAneurysm
        case arteriovenousMalformation
        case spinalCordInjury
        case hydrocephalus
        case custom
        
        var displayName: String {
            switch self {
            case .stroke:                         "AVC"
            case .transientIschemicAttack:        "AIT"
            case .epilepsy:                       "Epilepsia"
            case .parkinsonsDisease:              "Doença de Parkinson"
            case .multipleSclerosis:              "Esclerose Múltipla"
            case .alzheimersDisease:              "Doença de Alzheimer"
            case .guillainBarreSyndrome:          "Síndrome de Guillain-Barré"
            case .cerebralAneurysm:               "Aneurisma Cerebral"
            case .arteriovenousMalformation:      "Malformação Arteriovenosa"
            case .spinalCordInjury:               "Lesão Medular"
            case .hydrocephalus:                  "Hidrocefalia"
            case .custom :                        "Outros"
            }
        }

    static var customCase: NeuroComorbidityCode { .custom }
}

enum GeneticComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case downSyndrome
    case turnerSyndrome
    case klinefelterSyndrome
    case marfanSyndrome
    case pierreRobinSequence
    case achondroplasia
    case osteogenesisImperfecta
    case malignantHyperthermia
    case custom
    
    var displayName: String {
        switch self {
        case .downSyndrome:                   "Síndrome de Down"
        case .turnerSyndrome:                 "Síndrome de Turner"
        case .klinefelterSyndrome:            "Síndrome de Klinefelter"
        case .marfanSyndrome:                 "Síndrome de Marfan"
        case .pierreRobinSequence:            "Sequência de Pierre Robin"
        case .achondroplasia:                 "Acondroplasia"
        case .osteogenesisImperfecta:         "Osteogênese Imperfeita"
        case .malignantHyperthermia:          "Hipertermia Maligna"
        case .custom:                         "Outros"
        }
    }
    static var customCase: GeneticComorbidityCode { .custom }
}

enum InfectiousComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case hiv
    case syfilis
    case hepatitisB
    case hepatitisC
    case meningitis
    case sepsis
    case custom
    
    var displayName: String {
        switch self {
        case .hiv:                            "HIV"
        case .syfilis:                        "Sífilis"
        case .hepatitisB:                     "Hepatite B"
        case .hepatitisC:                     "Hepatite C"
        case .meningitis:                     "Meningite"
        case .sepsis:                         "Sepse"
        case .custom:                          "Outros"
        }
    }
    static var customCase: InfectiousComorbidityCode { .custom }
}

enum OncologicComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case breast
    case prostate
    case lung
    case colorectal
    case stomach
    case pancreas
    case cervix
    case uterus
    case ovary
    case bladder
    case kidney
    case thyroid
    case brain
    case leukemia
    case lymphoma
    case custom
    
    var displayName: String {
        switch self {
        case .breast:          "Mama"
        case .prostate:        "Próstata"
        case .lung:            "Pulmão"
        case .colorectal:      "Colorretal"
        case .stomach:         "Estômago"
        case .pancreas:        "Pâncreas"
        case .cervix:          "Colo do útero"
        case .uterus:          "Útero"
        case .ovary:           "Ovário"
        case .bladder:         "Bexiga"
        case .kidney:          "Rim"
        case .thyroid:         "Tireoide"
        case .brain:           "Sistema nervoso central"
        case .leukemia:        "Leucemia"
        case .lymphoma:        "Linfoma"
        case .custom:          "Outros"
        }
    }
    static var customCase: OncologicComorbidityCode { .custom }
}

enum GenitourinaryComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case chronicKidneyDisease
    case dialysis
    case kidneyTransplant
    case nephroticSyndrome
    case anatomyAlterations
    case urolithiasis
    case polycysticKidneyDisease
    case glomerulonephritis
    case acuteKidneyInjury
    case neurogenicBladder
    case pyelonephritis
    case sdt
    case custom
    
    var displayName: String {
        switch self {
        case .chronicKidneyDisease:           "Doença Renal Crônica"
        case .dialysis:                       "Diálise"
        case .kidneyTransplant:               "Transplante Renal"
        case .nephroticSyndrome:              "Síndrome Nefrótica"
        case .anatomyAlterations:             "Mal Formações Anatómicas"
        case .urolithiasis:                   "Urolitíase"
        case .polycysticKidneyDisease:        "Doença Renal Policística"
        case .glomerulonephritis:             "Glomerulonefrite"
        case .acuteKidneyInjury:              "Lesão Renal Aguda"
        case .neurogenicBladder:              "Bexiga Neurogênica"
        case .pyelonephritis:                 "Pielonefrite Crônica"
        case .sdt:                            "DST"
        case .custom:                          "Outros"
        }
    }
    static var customCase: GenitourinaryComorbidityCode { .custom }
}

enum GynecologicComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case polycysticOvarySyndrome
    case endometriosis
    case uterineFibroids
    case pelvicInflammatoryDisease
    case menorrhagia
    case pelvicOrganProlapse
    case chronicPelvicPain
    case ovariancCysts
    case adenomyosis
    case custom
    
    var displayName: String {
        switch self {
        case .polycysticOvarySyndrome:        "Síndrome de Ovários Policísticos"
        case .endometriosis:                  "Endometriose"
        case .uterineFibroids:                "Miomatose"
        case .pelvicInflammatoryDisease:      "Doença Inflamatória Pélvica"
        case .menorrhagia:                    "Menorragia"
        case .pelvicOrganProlapse:            "Prolapso de Órgãos Pélvicos"
        case .chronicPelvicPain:              "Dor Pélvica Crônica"
        case .ovariancCysts:                  "Cistos Ovarianos"
        case .adenomyosis:                    "Adenomiose"
        case .custom:                         "Outros"
        }
    }
    static var customCase: GynecologicComorbidityCode { .custom }
}

enum AndrologicComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case benignProstaticHyperplasia
    case varicocele
    case hydrocele
    case peyronie
    case urethralStricture
    case custom
    
    var displayName: String {
        switch self {
        case .benignProstaticHyperplasia:     "Hiperplasia Prostática Benigna"
        case .varicocele:                     "Varicocele"
        case .hydrocele:                      "Hidrocele"
        case .peyronie:                       "Doença de Peyronie"
        case .urethralStricture:              "Estenose Uretral"
        case .custom:                         "Outros"
        }
    }
    static var customCase: AndrologicComorbidityCode { .custom }
}

enum MusculoskeleticComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case osteoarthritis
    case ankylosingSpondylitis
    case kyphoscoliosis
    case muscularDystrophy
    case myastheniaGravis
    case osteoporosis
    case fibromyalgia
    case custom
    
    var displayName: String {
        switch self {
        case .osteoarthritis:                 "Osteoartrite"
        case .ankylosingSpondylitis:          "Espondilite Anquilosante"
        case .kyphoscoliosis:                 "Cifoescoliose"
        case .muscularDystrophy:              "Distrofia Muscular"
        case .myastheniaGravis:               "Miastenia Gravis"
        case .osteoporosis:                   "Osteoporose"
        case .fibromyalgia:                   "Fibromialgia"
        case .custom:                          "Outros"
        }
    }
    static var customCase: MusculoskeleticComorbidityCode { .custom }
}

enum ImmunologicComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case lupus
    case rheumatoidArthritis
    case organTransplant
    case immunosuppressiveTherapy
    case multipleMyeloma
    case vasculitis
    case psoriasis
    case inflammatoryBowelDisease
    case custom
    
    var displayName: String {
        switch self {
        case .lupus:                          "Lúpus Eritematoso Sistêmico"
        case .rheumatoidArthritis:            "Artrite Reumatoide"
        case .organTransplant:                "Transplante de Órgão"
        case .immunosuppressiveTherapy:       "Terapia Imunossupressora"
        case .multipleMyeloma:                "Mieloma Múltiplo"
        case .vasculitis:                     "Vasculite"
        case .psoriasis:                      "Psoríase"
        case .inflammatoryBowelDisease:       "Doença Inflamatória Intestinal"
        case .custom:                         "Outros"
        }
    }
    static var customCase: ImmunologicComorbidityCode { .custom }
}

enum HematologicComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case anemia
    case sickleCell
    case thalassemia
    case hemophilias
    case vonWillebrandDisease
    case thrombocytopenia
    case anticoagulantUse
    case thrombophilia
    case leukemia
    case lymphoma
    case custom
    
    var displayName: String {
        switch self {
        case .anemia:                         "Anemia"
        case .sickleCell:                     "Anemia Falciforme"
        case .thalassemia:                    "Talassemia"
        case .hemophilias:                    "Hemofilia"
        case .vonWillebrandDisease:           "Doença de von Willebrand"
        case .thrombocytopenia:               "Trombocitopenia"
        case .anticoagulantUse:               "Uso de Anticoagulantes"
        case .thrombophilia:                  "Trombofilia"
        case .leukemia:                       "Leucemia"
        case .lymphoma:                       "Linfoma"
        case .custom:                          "Outros"
        }
    }
    static var customCase: HematologicComorbidityCode { .custom }
}

enum GastrointestinalComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case gastroesophagealReflux
    case crohnsDisease
    case colelitiasis
    case celiacDisease
    case fattyLiverDisease
    case cirrosis
    case diverticulitis
    case gastroparesis
    case varisisEsofagea
    case custom
    
    var displayName: String {
        switch self {
        case .gastroesophagealReflux:         "Refluxo Gastroesofágico"
        case .crohnsDisease:                  "Doença de Crohn"
        case .colelitiasis:                   "Colelitíase"
        case .celiacDisease:                  "Doença Celíaca"
        case .fattyLiverDisease:              "Esteatose Hepática"
        case .cirrosis:                       "Cirrose Hepática"
        case .diverticulitis:                 "Diverticulite"
        case .gastroparesis:                  "Gastroparesia"
        case .varisisEsofagea:                "Varizes Esofágicas"
        case .custom:                         "Outros"
        }
    }
    static var customCase: GastrointestinalComorbidityCode { .custom }
}

enum EndocrineComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case diabetesType1
    case diabetesType2
    case hypothyroidism
    case cushingSyndrome
    case hyperthyroidism
    case methabolicSyndrome
    case hypogonadism
    case custom
    
    var displayName: String {
        switch self {
        case .diabetesType1:                  "Diabetes T1"
        case .diabetesType2:                  "Diabetes T2"
        case .hypothyroidism:                 "Hipotiroidismo"
        case .cushingSyndrome:                "Síndrome de Cushing"
        case .hyperthyroidism:                "Hipertireoidismo"
        case .methabolicSyndrome:             "Síndrome Metabólica"
        case .hypogonadism:                   "Hipogonadismo"
        case .custom :                         "Outros"
        }
    }
    static var customCase: EndocrineComorbidityCode { .custom }
}

enum RespiratoryComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case asthma
    case chronicBronchitis
    case emphysema
    case pneumonia
    case tuberculosis
    case DPCO
    case fibrosis
    case estenosisAirway
    case sleepDisorders
    case custom
    
    var displayName: String {
        switch self {
        case .asthma:                         "Asma"
        case .chronicBronchitis:              "Bronquite Crónica"
        case .emphysema:                      "Enfisema"
        case .pneumonia:                      "Pneumonia"
        case .tuberculosis:                   "Tuberculose"
        case .DPCO:                           "DPOC"
        case .fibrosis:                       "Fibrose Pulmonar"
        case .estenosisAirway:                "Estenose Via Respiratória"
        case .sleepDisorders:                 "Distúrbios do Sono"
        case .custom:                          "Outros"
        }
    }
    static var customCase: RespiratoryComorbidityCode { .custom }
}

enum InfantComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case prematureBirth
    case lowWeightAtBirth
    case fetalGrowthRestriction
    case fetalAbnormality
    case cSectionBirth
    case naturalBirth
    case birthComplications
    case healthy
    case custom
    
    var displayName: String {
        switch self {
        case .prematureBirth:           "Prematuridade"
        case .lowWeightAtBirth:         "Baixo Peso ao Nascer"
        case .fetalGrowthRestriction:   "Crescimento Fetal Restrito"
        case .fetalAbnormality:         "Mal formação fetal"
        case .cSectionBirth:            "Parto Cesárea"
        case .naturalBirth:             "Parto Natural"
        case .birthComplications:       "Complicações do Parto"
        case .healthy:                  "Saudável"
        case .custom:                   "Outros"
        }
    }
    var reportDisplayName: String {
        switch self {
        case .prematureBirth:           "Prematuridade"
        case .lowWeightAtBirth:         "Baixo Peso ao Nascer"
        case .fetalGrowthRestriction:   "Restrição de Crescimento Fetal"
        case .fetalAbnormality:         "Mal formação fetal"
        case .cSectionBirth:            "Parto Cesárea"
        case .naturalBirth:             "Parto Natural"
        case .birthComplications:       "Complicações do Parto"
        case .healthy:                   "Saudável"
        case .custom:                   "Outros"
        }
    }
    static var customCase: InfantComorbidityCode { .custom }
}

enum PregnantComorbidityCode: String, Codable, CaseIterable, DomainCode {
    case diabetesGestationalis
    case hypartensionGestationalis
    case ectopicGestationalis
    case hellpSyndrome
    case eclapsisGestationalis
    case placentaPrevia
    case prematureLabor
    case healthy
    case custom
    
    var displayName: String {
        switch self {
        case .diabetesGestationalis:           "Diabetes Gestacional"
        case .hypartensionGestationalis:       "Hipertensão Gestacional"
        case .ectopicGestationalis:            "Gestação Ectópica"
        case .hellpSyndrome:                   "Síndrome Hellp"
        case .eclapsisGestationalis:           "Ecâmpsia"
        case .placentaPrevia:                  "Acretismo Placentário"
        case .prematureLabor:                  "Trabalho de Parto Prematuro"
        case .healthy:                         "Saudável"
        case .custom:                          "Outros"
        }
    }
    static var customCase: PregnantComorbidityCode { .custom }
}
