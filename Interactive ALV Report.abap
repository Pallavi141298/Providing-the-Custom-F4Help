TYPE-POOLS SLIS.        "Type pools declaration for ALV fieldcat purpose.

TABLES PERNR.

INFOTYPES: 0001, 0002, 0007, 0008.

DATA: WA_PBWLA     TYPE PBWLA,

      PBWLA        TYPE TABLE OF PBWLA,

      IT_FIELDCAT1 TYPE SLIS_T_FIELDCAT_ALV WITH HEADER LINE,

      IT_FIELDCAT2 TYPE SLIS_T_FIELDCAT_ALV WITH HEADER LINE,
      WA_FCAT      TYPE SLIS_FIELDCAT_ALV.

DATA: BEGIN OF IT_PBWLA OCCURS 0,

        PERNR TYPE PERNR-PERNR,

        WAERS TYPE PBWLA-WAERS,

        LGART TYPE PBWLA-LGART,

        LGTXT TYPE T512T-LGTXT,

        BETRG TYPE PBWLA-BETRG,

        INDBW TYPE PBWLA-INDBW,

      END OF IT_PBWLA.

DATA: BEGIN OF IT_PAGE1 OCCURS 0,      "Internal table for First page ALV

        PERNR       TYPE PERNR-PERNR,         "Which contains Emp no, Name, Hire date, Total All wage types amount

        EMPNAME(80) TYPE C,

        CURR        TYPE PBWLA-WAERS,

        AMOUNT      TYPE Q0008-SUMBB,

      END OF IT_PAGE1.

DATA: BEGIN OF IT_PAGE2 OCCURS 0,      " Internal table for Second page in ALV output"

        PERNR TYPE PERNR-PERNR,

        LGART TYPE PBWLA-LGART,

        LGTXT TYPE T512T-LGTXT,

        WAERS TYPE PBWLA-WAERS,

        BETRG TYPE PBWLA-BETRG,

        INDBW TYPE PBWLA-INDBW,

      END OF IT_PAGE2.

DATA: BEGIN OF IT_T512T OCCURS 0,

        MOLGA TYPE T512T-MOLGA,

        LGART TYPE T512T-LGART,

        LGTXT TYPE T512T-LGTXT,

      END OF IT_T512T.

********** Start of selection event*****

START-OF-SELECTION.

** READ ALL THE WAGE TYPE DESCRIPTIONS .

  SELECT MOLGA LGART LGTXT FROM T512T

                           INTO TABLE IT_T512T

                           WHERE SPRSL = SY-LANGU.

  SORT IT_T512T BY LGART MOLGA.

** Get pernr event

GET PERNR.

** Read the latest record to header of infotype 8 internal table.

  RP-PROVIDE-FROM-LAST P0008 SPACE PN-BEGDA PN-ENDDA.

  IF PNP-SW-FOUND = 1.

** Call the function module to fill the employee all wage type details

    CALL FUNCTION 'RP_FILL_WAGE_TYPE_TABLE_EXT'
      EXPORTING
        BEGDA                        = P0008-BEGDA
        ENDDA                        = P0008-ENDDA
        INFTY                        = '0008'
        PERNR                        = PERNR-PERNR
      TABLES
        PP0001                       = P0001
        PP0007                       = P0007
        PP0008                       = P0008
        PPBWLA                       = PBWLA
      EXCEPTIONS
        ERROR_AT_INDIRECT_EVALUATION = 1
        OTHERS                       = 2.

    IF SY-SUBRC <> 0.

      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO

              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.

    ENDIF.

** Get the total amount in basic pay infotype using the below function module.

    CALL FUNCTION 'HR_GET_TOTAL_AMOUNT_P0008'
      EXPORTING
        PERNR             = PERNR-PERNR
        P0008             = P0008
        P0001             = P0001
      IMPORTING
        AMOUNT            = IT_PAGE1-AMOUNT
        CURRENCY          = IT_PAGE1-CURR
      EXCEPTIONS
        NO_ENTRY_IN_T001P = 1
        NO_ENTRY_IN_T503  = 2
        OTHERS            = 3.

    IF SY-SUBRC <> 0.

      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO

              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.

    ENDIF.

** Concatinate the first and last name of employee

    RP-PROVIDE-FROM-LAST P0002 SPACE PN-BEGDA PN-ENDDA.

    CONCATENATE P0002-NACHN P0002-VORNA INTO IT_PAGE1-EMPNAME.

** Append the total amount of all wage types amount to ALV first page internal table.

    IT_PAGE1-PERNR = PERNR-PERNR.

    APPEND IT_PAGE1.

** Append all employee basic pay records to a single internal table ( it_pbwla).

    LOOP AT PBWLA INTO WA_PBWLA.

      READ TABLE IT_T512T WITH KEY LGART = WA_PBWLA-LGART MOLGA = WA_PBWLA-MOLGA BINARY SEARCH.

      MOVE IT_T512T-LGTXT TO IT_PBWLA-LGTXT.

      MOVE-CORRESPONDING WA_PBWLA TO IT_PBWLA.

      MOVE PERNR-PERNR TO IT_PBWLA-PERNR.

      APPEND IT_PBWLA.

      CLEAR IT_PBWLA.

    ENDLOOP.

  ENDIF.

END-OF-SELECTION.

** CALL THE INTERACTIVE ALV GRID DISPLAY FUNCTION TO DISPALY THE ALL

** EMPLOYEE DETAILS WITH TOTAL WAGE TYPES AMOUNT , EMP NAME, EMP NO.

  WA_FCAT-COL_POS = '1'.
  WA_FCAT-FIELDNAME = 'PERNR'.
  WA_FCAT-SELTEXT_L = 'EMP NO'.
  APPEND WA_FCAT TO IT_FIELDCAT1.

  WA_FCAT-COL_POS = '2'.
  WA_FCAT-FIELDNAME = 'EMPNAME'.
  WA_FCAT-SELTEXT_L = 'EMP NAME'.
  APPEND WA_FCAT TO IT_FIELDCAT1.

  WA_FCAT-COL_POS = '3'.
  WA_FCAT-FIELDNAME = 'CURR'.
  WA_FCAT-SELTEXT_L = 'CUR FORMAT'.
  APPEND WA_FCAT TO IT_FIELDCAT1.

  WA_FCAT-COL_POS = '4'.
  WA_FCAT-FIELDNAME = 'AMOUNT'.
  WA_FCAT-SELTEXT_L = 'TOTAL WAGE TYPES AMOUNT'.
  APPEND WA_FCAT TO IT_FIELDCAT1.
*  PERFORM APPEND_FIELDCAT USING 'PERNR' 'EMP NO' 'X'  " .
*
*  PERFORM APPEND_FIELDCAT USING 'EMPNAME' 'EMP NAME' " " .
*
*  PERFORM APPEND_FIELDCAT USING 'CURR' 'CUR FORMAT' " " .
*
*  PERFORM APPEND_FIELDCAT USING 'AMOUNT' 'TOTAL WAGE TYPES AMOUNT'  " .

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      I_CALLBACK_PROGRAM      = SY-REPID
*     I_CALLBACK_PF_STATUS_SET    = ‘ ‘
      I_CALLBACK_USER_COMMAND = 'SECOND_PAGE'
*     I_CALLBACK_TOP_OF_PAGE  = ‘ ‘
*     IS_LAYOUT               =
      IT_FIELDCAT             = IT_FIELDCAT1[]
    TABLES
      T_OUTTAB                = IT_PAGE1
    EXCEPTIONS
      PROGRAM_ERROR           = 1
      OTHERS                  = 2.

  IF SY-SUBRC <> 0.

    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO

            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.

  ENDIF.


FORM APPEND_FIELDCAT  USING    VALUE(P_0328)

                               VALUE(P_0329)

                               VALUE(P_0330)

                               VALUE(P_0331).

  IT_FIELDCAT1-FIELDNAME = P_0328.

  IT_FIELDCAT1-SELTEXT_L = P_0329.

  IT_FIELDCAT1-HOTSPOT = P_0330.

  APPEND IT_FIELDCAT1.

  CLEAR IT_FIELDCAT1.

ENDFORM.



FORM SECOND_PAGE USING R_UCOMM LIKE SY-UCOMM

                                   RS_SELFIELD TYPE SLIS_SELFIELD.

** CHECK WHETHER THE USER CLICKED ON EMP NUMBER OR NOT. IF

** YES DISPALY DETAILED WAGE TYPES INFORMATIN IN SECOND PAGE.

  IF RS_SELFIELD-FIELDNAME = 'PERNR'.

    LOOP AT IT_PBWLA WHERE PERNR = RS_SELFIELD-VALUE.

      MOVE-CORRESPONDING IT_PBWLA TO IT_PAGE2.

      APPEND IT_PAGE2.

      CLEAR IT_PAGE2.

    ENDLOOP.

** PROCESS THE ALV SECOND PAGE.
    WA_FCAT-COL_POS = '1'.
    WA_FCAT-FIELDNAME = 'PERNR'.
    WA_FCAT-SELTEXT_L = 'EMP NO'.
    APPEND WA_FCAT TO IT_FIELDCAT2.

    WA_FCAT-COL_POS = '2'.
    WA_FCAT-FIELDNAME = 'LGART'.
    WA_FCAT-SELTEXT_L = 'WAGE TYPE'.
    APPEND WA_FCAT TO IT_FIELDCAT2.

    WA_FCAT-COL_POS = '3'.
    WA_FCAT-FIELDNAME = 'LGTXT'.
    WA_FCAT-SELTEXT_L = 'DESCIRPTION'.
    APPEND WA_FCAT TO IT_FIELDCAT2.

    WA_FCAT-COL_POS = '4'.
    WA_FCAT-FIELDNAME = 'WAERS'.
    WA_FCAT-SELTEXT_L = 'CURRENCY'.
    APPEND WA_FCAT TO IT_FIELDCAT2.

    WA_FCAT-COL_POS = '5'.
    WA_FCAT-FIELDNAME = 'BETRG'.
    WA_FCAT-SELTEXT_L = 'AMOUNT'.
    APPEND WA_FCAT TO IT_FIELDCAT2.

    WA_FCAT-COL_POS = '6'.
    WA_FCAT-FIELDNAME = 'INDBW'.
    WA_FCAT-SELTEXT_L = 'IND EVAL'.
    APPEND WA_FCAT TO IT_FIELDCAT2.

*    PERFORM APPEND_FIELDCAT2 USING 'PERNR' 'EMP NO.' ".
*
*    PERFORM APPEND_FIELDCAT2 USING 'LGART' 'WAGE TYPE' ".
*
*    PERFORM APPEND_FIELDCAT2 USING 'LGTXT' 'DESCIRPTION'  ".
*
*    PERFORM APPEND_FIELDCAT2 USING 'WAERS' 'CURRENCY'  ".
*
*    PERFORM APPEND_FIELDCAT2 USING 'BETRG' 'AMOUNT' ”.
*
*    PERFORM APPEND_FIELDCAT2 USING 'INDBW' 'IND EVAL' ".

** CALL THE ALV FUNCTION MODULE.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
*       IS_LAYOUT     =
        IT_FIELDCAT   = IT_FIELDCAT2[]
      TABLES
        T_OUTTAB      = IT_PAGE2
      EXCEPTIONS
        PROGRAM_ERROR = 1
        OTHERS        = 2.

    IF SY-SUBRC <> 0.

      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO

              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.

    ENDIF.

  ENDIF.

ENDFORM.



FORM APPEND_FIELDCAT2  USING    VALUE(P_0459)

                                VALUE(P_0460)

                                VALUE(P_0461).

  IT_FIELDCAT2-FIELDNAME = P_0459.

  IT_FIELDCAT2-SELTEXT_L = P_0460.

  APPEND IT_FIELDCAT2.

  CLEAR IT_FIELDCAT2.

ENDFORM.
