//
//   Copyright (C) 1998-2011 by Galerna Project, the University of
//   Cantabria, Spain.
//
//   This file is part of the TOPAZ network simulator, originallty developed
//   at the Unviersity of Cantabria
//
//   TOPAZ shares a large proportion of code with SICOSYS which was
//   developed by V.Puente and J.M.Prellezo
//
//   TOPAZ has been developed by P.Abad, L.G.Menezo, P.Prieto and
//   V.Puente
//
//  --------------------------------------------------------------------
//
//  If your use of this software contributes to a published paper, we
//  request that you (1) cite our summary paper that appears on our
//  website (http://www.atc.unican.es/topaz/) and (2) e-mail a citation
//  for your published paper to topaz@atc.unican.es
//
//  If you redistribute derivatives of this software, we request that
//  you notify us and either (1) ask people to register with us at our
//  website (http://www.atc.unican.es/topaz/) or (2) collect registration
//  information and periodically send it to us.
//
//   --------------------------------------------------------------------
//
//   TOPAZ is free software; you can redistribute it and/or
//   modify it under the terms of version 2 of the GNU General Public
//   License as published by the Free Software Foundation.
//
//   TOPAZ is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//   General Public License for more details.
//
//   You should have received a copy of the GNU General Public License
//   along with the TOPAZ simulator; if not, write to the Free Software
//   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
//   02111-1307, USA
//
//   The GNU General Public License is contained in the file LICENSE.
//
//
//*************************************************************************
//:
//    File: TPZSimpleRouterFlowBless.hpp
//
//    Class: TPZSimpleRouterFlowBless
//
//    Inherited from: TPZFlow
// :
//*************************************************************************
//end of header


#ifndef __TPZSimpleRouterFlowBless_HPP__
#define __TPZSimpleRouterFlowBless_HPP__

//*************************************************************************

   #include <TPZFlow.hpp>

   #ifndef __TPZArray_HPP__
   #include <TPZArray.hpp>
   #endif

   #ifndef __TPZPriorityQueue_HPP__
   #include <TPZPriorityQueue.hpp>
   #endif

   #ifndef __TPZQueue_HPP__
   #include <TPZQueue.hpp>
   #endif

   #ifndef __TPZPair_HPP__
   #include <TPZPair.hpp>
   #endif

//*************************************************************************

   class TPZMessage;

//*************************************************************************

   typedef TPZPriorityQueue<TPZMessage*>      TPZArbitrationQueue;
   typedef TPZQueue<TPZMessage*>              TPZInjectionQueue;
//*************************************************************************

   class TPZSimpleRouterFlowBless : public TPZFlow
   {
      typedef TPZFlow Inhereited;


   public:
      TPZSimpleRouterFlowBless( TPZComponent& component);
      virtual ~TPZSimpleRouterFlowBless();

      virtual void initialize();
      virtual void terminate();

      virtual Boolean controlAlgoritm(Boolean info=false, int delta=0);
      virtual Boolean inputReading();
      virtual Boolean stateChange();
      virtual Boolean outputWriting();

      virtual Boolean onReadyUp(unsigned interfaz, unsigned cv);
      virtual Boolean onStopUp(unsigned interfaz, unsigned cv);
      virtual Boolean onStopDown(unsigned interfaz, unsigned cv);
      virtual TPZString getStatus() const;

      // Run time information
      DEFINE_RTTI(TPZSimpleRouterFlowBless);

   protected:
      virtual  void    cleanOutputInterfaces();
      virtual  void    cleanInputInterfaces();

      virtual  Boolean updateMessageInfo(TPZMessage* msg, unsigned outPort);
      virtual  Boolean getDeltaAbs(TPZMessage* msg, unsigned outPort);
      virtual  Boolean dispatchEvent(const TPZEvent& event);

   protected:
      Boolean cleanInterfaces() const
      { return m_CleanInterfaces; }
      void setCleanInterfaces(Boolean value)
      { m_CleanInterfaces = value; }
      Boolean m_CleanInterfaces;

      void checkAllocation();
      void ejectLocal();
      void injectBypass();
      Boolean injectLocal();
      void sendFlit();
      void clearPipeline1 ();
      void clearPipeline2 ();
      void pipelining();
      void permutationNetwork();
      void swapMsg (TPZMessage* & msg0, TPZMessage* & msg1, Boolean swapEnable);
      void swapPV (Boolean* & PV0, Boolean* & PV1, Boolean swapEnable);
      Boolean swapCtrl (TPZMessage * msg0, TPZMessage * msg1, Boolean * PV0, Boolean * PV1, unsigned mode);
      void resolveConflict (Boolean * &PV0, Boolean * &PV1, Boolean * &previousPV0, Boolean * &previousPV1, Boolean swapEnable, unsigned mode);
      void computePV1 (TPZMessage* msg, unsigned index);
      void computePV2 (TPZMessage* msg, unsigned index);
      Boolean routeComputation(TPZMessage* msg);
      void filterPV();
      void computePVBypass (TPZMessage* msg);
      void debugStop(unsigned pktId, unsigned flitId, TPZString router);
      
   protected:
      TPZMessage** m_sync;
      TPZMessage** m_pipelineReg1;
      TPZInjectionQueue m_injectionQueue;
      unsigned m_ports;
      Boolean ** m_productiveVector1;
      Boolean ** m_productiveVector2;
      Boolean ** m_previousPV;
};

//*************************************************************************


#endif


// end of file
