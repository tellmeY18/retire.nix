    Scope (_SB.PCI0.SPI0)
    {
        Device (FPRT)
        {
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                If (((TPDI & 0x24) == 0x24))
                {
                    Return ("ELAN7001")
                }

                If (((TPDI & 0x30) == 0x30))
                {
                    Return ("FTE7001")
                }

                Return ("ELAN7001")
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((TPDI & 0x20))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                Name (BBUF, ResourceTemplate ()
                {
                    SpiSerialBusV2 (0x0000, PolarityLow, FourWireMode, 0x08,
                        ControllerInitiated, 0x000F4240, ClockPolarityLow,
                        ClockPhaseFirst, "\\_SB.PCI0.SPI0",
                        0x00, ResourceConsumer, _Y42, Exclusive,
                        )
                })
                Name (RBUF, ResourceTemplate ()
                {
                    GpioIo (Exclusive, PullDefault, 0x0000, 0x0000, IoRestrictionOutputOnly,
                        "\\_SB.GPI0", 0x00, ResourceConsumer, _Y43,
                        )
                        {   // Pin list
                            0x0000
                        }
                })
                Name (IBUF, ResourceTemplate ()
                {
                    GpioInt (Edge, ActiveHigh, Exclusive, PullNone, 0x0000,
                        "\\_SB.GPI0", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            0x0000
                        }
                })
                CreateDWordField (BBUF, \_SB.PCI0.SPI0.FPRT._CRS._Y42._SPE, SPEX)  // _SPE: Speed
                CreateWordField (RBUF, 0x17, RST0)
                CreateByteField (RBUF, \_SB.PCI0.SPI0.FPRT._CRS._Y43._PPI, PCG0)  // _PPI: Pin Configuration
                CreateWordField (IBUF, 0x17, INT0)
                RST0 = GNUM (0x0602000F)
                INT0 = GNUM (0x06030010)
                If (((TPDI & 0x24) == 0x24))
                {
                    SPEX = 0x00B71B00
                    PCG0 = Zero
                }

                If (((TPDI & 0x30) == 0x30))
                {
                    SPEX = 0x000F4240
                    PCG0 = One
                }

                Return (ConcatenateResTemplate (BBUF, ConcatenateResTemplate (RBUF, IBUF)))
            }
        }
    }
}

