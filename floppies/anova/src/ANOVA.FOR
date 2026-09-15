      PROGRAM ANOVA
C     One-way fixed-effects ANOVA, Microsoft FORTRAN 5, 8086 DOS.
      INTEGER K,N(10),I,J,NT,DFB,DFW,IOS,INUNIT
      COMMON /INPUT/ INUNIT
      CHARACTER*80 FNAME
      DOUBLE PRECISION X(100,10),MEAN(10),SS(10),GRAND
      DOUBLE PRECISION VALUE,DELTA,SSB,SSW,SST,MSB,MSW,F
      INUNIT=5
      WRITE(*,'(1X,A)') 'ONE-WAY ANOVA - MICROSOFT FORTRAN 5'
      WRITE(*,'(1X,A)') 'Data filename (Enter for keyboard input):'
      READ(*,'(A)',IOSTAT=IOS) FNAME
      IF (IOS.NE.0) GOTO 900
      IF (FNAME.NE.' ') THEN
        INUNIT=10
        OPEN(10,FILE=FNAME,STATUS='OLD',IOSTAT=IOS)
        IF (IOS.NE.0) THEN
          WRITE(*,'(1X,A)') 'ERROR: cannot open data file.'
          STOP 1
        ENDIF
      ENDIF
      WRITE(*,'(1X,A)') 'Enter one number per line.'
      WRITE(*,'(1X,A)') 'Number of groups (2-10):'
      CALL NUMBER(VALUE,IOS)
      IF (IOS.NE.0) GOTO 900
      IF (VALUE.LT.2D0.OR.VALUE.GT.10D0) GOTO 910
      K=INT(VALUE)
      IF (DBLE(K).NE.VALUE) GOTO 910
      NT=0
      GRAND=0D0
      DO 100 I=1,K
        WRITE(*,1000) I
        CALL NUMBER(VALUE,IOS)
        IF (IOS.NE.0) GOTO 900
        IF (VALUE.LT.1D0.OR.VALUE.GT.100D0) GOTO 920
        N(I)=INT(VALUE)
        IF (DBLE(N(I)).NE.VALUE) GOTO 920
        MEAN(I)=0D0
        DO 50 J=1,N(I)
          WRITE(*,1010) J
          CALL NUMBER(VALUE,IOS)
          IF (IOS.NE.0) GOTO 900
          X(J,I)=VALUE
          MEAN(I)=MEAN(I)+(VALUE-MEAN(I))/DBLE(J)
          NT=NT+1
          GRAND=GRAND+(VALUE-GRAND)/DBLE(NT)
   50   CONTINUE
  100 CONTINUE
      IF (NT.LE.K) GOTO 930
C     Centered sums avoid subtracting two large raw sum-of-squares.
      SSB=0D0
      SSW=0D0
      DO 200 I=1,K
        SS(I)=0D0
        DO 150 J=1,N(I)
          DELTA=X(J,I)-MEAN(I)
          SS(I)=SS(I)+DELTA*DELTA
  150   CONTINUE
        SSW=SSW+SS(I)
        DELTA=MEAN(I)-GRAND
        SSB=SSB+DBLE(N(I))*DELTA*DELTA
  200 CONTINUE
      SST=SSB+SSW
      DFB=K-1
      DFW=NT-K
      MSB=SSB/DBLE(DFB)
      MSW=SSW/DBLE(DFW)
      WRITE(*,'(/,1X,A)') 'GROUP     N                 MEAN'
      DO 250 I=1,K
        WRITE(*,1020) I,N(I),MEAN(I)
  250 CONTINUE
      WRITE(*,1030) 'GRAND MEAN',GRAND
      WRITE(*,'(/,1X,A)') 'SOURCE        DF        SS               MS'
      WRITE(*,1040) 'BETWEEN',DFB,SSB,MSB
      WRITE(*,1040) 'WITHIN',DFW,SSW,MSW
      WRITE(*,1050) 'TOTAL',NT-1,SST
      IF (MSW.EQ.0D0) THEN
        WRITE(*,'(1X,A)') 'F UNDEFINED: zero within-group variance.'
      ELSE
        F=MSB/MSW
        WRITE(*,1030) 'F STATISTIC',F
      ENDIF
      WRITE(*,'(1X,A)') 'Use numerator/denominator df with an F table.'
      STOP
  900 WRITE(*,'(1X,A)') 'ERROR: expected number, abs(x) <= 1E100.'
      STOP 1
  910 WRITE(*,'(1X,A)') 'ERROR: group count must be an integer 2-10.'
      STOP 1
  920 WRITE(*,'(1X,A)') 'ERROR: group size must be an integer 1-100.'
      STOP 1
  930 WRITE(*,'(1X,A)') 'ERROR: need positive within-group degrees of'
      WRITE(*,'(1X,A)') 'freedom (more observations than groups).'
      STOP 1
 1000 FORMAT(1X,'Group ',I2,': number of observations (1-100):')
 1010 FORMAT('  Observation ',I3,':')
 1020 FORMAT(I5,I6,3X,1PD22.12)
 1030 FORMAT(1X,A,': ',1PD22.12)
 1040 FORMAT(A10,I6,2(1X,1PD18.10))
 1050 FORMAT(A10,I6,1X,1PD18.10)
      END

      SUBROUTINE NUMBER(VALUE,IOS)
      DOUBLE PRECISION VALUE
      INTEGER IOS,INUNIT
      COMMON /INPUT/ INUNIT
      CHARACTER*120 LINE
      VALUE=2D100
      READ(INUNIT,'(A)',IOSTAT=IOS) LINE
      IF (IOS.NE.0) RETURN
      IF (LINE.EQ.' ') THEN
        IOS=1
        RETURN
      ENDIF
      READ(LINE,'(F120.0)',IOSTAT=IOS) VALUE
      IF (IOS.NE.0) RETURN
      IF (DABS(VALUE).GT.1D100) IOS=1
      END
