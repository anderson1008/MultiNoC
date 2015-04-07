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
//    File: TPZSimpleRouterFlowBless.cpp
//
//    Class:  TPZSimpleRouterFlowBless
//
//    Inherited from:  TPZFlow
// :
//*************************************************************************
//end of header

#include <TPZSimpleRouterFlowBless.hpp>

#ifndef __TPZInterfaz_HPP__
#include <TPZInterfaz.hpp>
#endif

#ifndef __TPZFicheroLog_HPP__
#include <TPZFicheroLog.hpp>
#endif

#ifndef __TPZSimulation_HPP__
#include <TPZSimulation.hpp>
#endif

#ifndef __TPZRouter_HPP__
#include <TPZRouter.hpp>
#endif

#ifndef __TPZSimpleRouter_HPP__
#include <TPZSimpleRouter.hpp>
#endif

//*************************************************************************

IMPLEMENT_RTTI_DERIVED(TPZSimpleRouterFlowBless,TPZFlow);

//*************************************************************************
//:
//  f: TPZSimpleRouterFlow();
//
//  d:
//:
//*************************************************************************

TPZSimpleRouterFlowBless :: TPZSimpleRouterFlowBless( TPZComponent& component)
                 : TPZFlow(component)
{
}


//*************************************************************************
//:
//  f: ~TPZSimpleRouterFlow();
//
//  d:
//:
//*************************************************************************

TPZSimpleRouterFlowBless :: ~TPZSimpleRouterFlowBless()
{
}


//*************************************************************************
//:
//  f: virtual void initialize();
//
//  d:
//:
//*************************************************************************

/*
   Local injection and bypass can skip prioritization.
   They only experience 1 cycle latency.
*/

void TPZSimpleRouterFlowBless :: initialize()
{
   Inhereited :: initialize();

   m_ports=((TPZSimpleRouter&)getComponent()).numberOfInputs();
   //m_connections=new unsigned[m_ports+1];
   m_sync=new TPZMessage*[m_ports+1];
   m_pipelineReg1=new TPZMessage*[m_ports+1];
   m_productiveVector1=new Boolean*[m_ports+1]; // only 1-4 are effective
   m_productiveVector2=new Boolean*[m_ports+1];
   m_previousPV=new Boolean*[m_ports+1];
   //m_connEstablished=new Boolean[m_ports+1];
   //m_bypass = 0;

   for(int i=0; i<m_ports+1; i++)
   {
      //m_connections[i] = 0;
      //m_connEstablished[i] = false;
      m_sync[i]=0;
      m_pipelineReg1[i]=0;
      m_productiveVector1[i] = 0;
      m_productiveVector2[i] = 0;
      m_previousPV[i] = 0;

      m_productiveVector1[i] = new Boolean [m_ports+1];
      m_productiveVector2[i] = new Boolean [m_ports+1];
      m_previousPV[i] = new Boolean [m_ports+1];

      for (int j=0; j<m_ports+1; j++)
      {
         m_productiveVector1[i][j] = false;
         m_productiveVector2[i][j] = false;
         m_previousPV[i][j] = false;
      }
   }

   setCleanInterfaces(true);
}

//unsigned NUM_LOCAL_PORT = 1; // number of injector
//unsigned NUM_BYPASS_PORT = 1; // number of bypass port

//*************************************************************************
//:
//  f: virtual void terminate();
//
//  d:
//:
//*************************************************************************

void TPZSimpleRouterFlowBless :: terminate()
{
//   delete[] m_connections;
   delete[] m_sync;
   delete[] m_pipelineReg1;
//   delete[] m_connEstablished;
   delete[] m_productiveVector1;
   delete[] m_productiveVector2;
}

void  TPZSimpleRouterFlowBless :: debugStop(unsigned pktId, unsigned flitId, TPZString router)
{
   unsigned stopPktId, stopFlitId;
   char * stopRouter;
   stopPktId = 3040;
   stopFlitId = 1;
   Boolean stop;

   if (stopPktId==pktId && stopFlitId == flitId)
   {
      if (router == "ROUTER2(1,2,0)")
         stop=true;
   }
}

//*************************************************************************
//:
//  f: virtual Boolean inputReading();
//
//  d:
//:
//*************************************************************************
Boolean TPZSimpleRouterFlowBless :: inputReading()
{

   unsigned outPort;
   unsigned inPort;


   //**********************************************************************************************************
   // Pipeline Stage 2: Port Allocation & Switch Traversal
   // the egree/priority queue must remain completely empty, every message must find an output port.
   //**********************************************************************************************************
   
   for (inPort=1; inPort <= m_ports-2; inPort++)
   {
      if (m_pipelineReg1[inPort])
         debugStop(m_pipelineReg1[inPort]->getIdentifier(),m_pipelineReg1[inPort]->flitNumber(),getComponent().asString());  
   }

   cleanOutputInterfaces();
   injectBypass(); // if call before ejectLocal(), allow bypass flit to claim the local port. (side effect: reduce the chance of local injection); Has to resolve conflict with all the other flits before injecting bypass flit.
   checkAllocation();
   ejectLocal();
   injectLocal();
   sendFlit();
   clearPipeline2 ();

   //**********************************************************************************************************
   // PART1: move through all the sync (except injection, which has special treatment).
   // Put every message arrived into the only queue, ordered according to their priority (age)
   //**********************************************************************************************************
   for( inPort = 1; inPort <= m_ports-2; inPort++)
   {
      // Initialize m_productiveVector1 and m_previousPV
      for (outPort=1; outPort<m_ports+1; outPort++)
      {
         m_productiveVector1[inPort][outPort] = false;
         m_previousPV[inPort][outPort] = false;
      }

      // If there is a message at sync,
      if(m_sync[inPort])
      {
 
         debugStop(m_sync[inPort]->getIdentifier(),m_sync[inPort]->flitNumber(),getComponent().asString());  
         
         routeComputation(m_sync[inPort]);
         computePV1(m_sync[inPort],inPort);
      }
   }

   permutationNetwork();
   pipelining();
   clearPipeline1();

   return true;
}

void TPZSimpleRouterFlowBless :: filterPV()
{
   unsigned inPort, outPort;
   Boolean found;
   for (inPort=1; inPort<=m_ports-1; inPort++)
   {
      found=false;
      for (outPort=1; outPort<m_ports+1; outPort++)
      {
         if (found==false)
         {
            if (m_productiveVector2[inPort][outPort]==true)
               found=true;
         }
         else
            m_productiveVector2[inPort][outPort]=false;
      }
   }
}

void TPZSimpleRouterFlowBless :: checkAllocation()
{
   /*
      The productive ports of low priority flits may be masked out by high priority flit.
      Must statically assign a port to either bypass or deflect the flit.
   */
   
   unsigned index;
   unsigned inPort, outPort;
   
   Boolean * PPVExist = new Boolean [m_ports-1];
   
   for (inPort=1; inPort <= m_ports-1; inPort++) // channel 1-5
   {
      PPVExist[inPort] = false;
      for (outPort=1; outPort < m_ports+1; outPort++)
         PPVExist[inPort] = m_productiveVector2[inPort][outPort] | PPVExist[inPort];
   }

   // Must keep only one productive port per flit
   filterPV();

   // get the current unallocated ports
   Boolean * availablePV = new Boolean [m_ports+1];
   for   (outPort=1; outPort < m_ports+1; outPort++)
   {
      availablePV[outPort] = false;
      for (inPort=1; inPort <= m_ports-1; inPort++)
         availablePV[outPort] = m_productiveVector2[inPort][outPort] | availablePV[outPort];
      availablePV[outPort] = !availablePV[outPort];
   }

   // Check flit2
   if (PPVExist[2]==false && (m_pipelineReg1[2] != 0))
      m_productiveVector2[2][5] = true; // bypass. flit2 never gets deflect.

   // Check flit3
   if (PPVExist[3]==false && (m_pipelineReg1[3] != 0))
   {
      if(PPVExist[2]==false) // check if the previous high priority flit is routed normally
      {
         // deflect to the first available port.
         for (outPort = 1; outPort <= m_ports-2; outPort++) // not including bypass and local port
            if (availablePV[outPort]==true)
            {
               m_productiveVector2[3][outPort] = true;
               break;
            }
      }
      else //bypass when flit2 is routed to productive port.
         m_productiveVector2[3][5] = true;
   }

   // Check flit4
   if (PPVExist[4]==false && (m_pipelineReg1[4] != 0))
   {
      if ((PPVExist[2]|PPVExist[3])==false) // both flit 2 and 3 do not have productive port
      {
         // deflect to the second available port.
         unsigned skip = 0;
         for (outPort = 1; outPort <= m_ports-2; outPort++) // not including bypass and local port
         {
            if (availablePV[outPort]==true)
            {
               if (skip == 1)
               {
                  m_productiveVector2[4][outPort] = true;
                  break;
               }
               skip ++;
            }
         }

      }
      else if((PPVExist[2]^PPVExist[3])==true) // flit 2 or flit3 is bypassed
      {
         // deflect to the first available port.
         for (outPort = 1; outPort <= m_ports-2; outPort++) // // not including bypass and local port
         {
            if (availablePV[outPort]==true)
            {
               m_productiveVector2[4][outPort] = true;
               break;
            }
         }
      }
      else if ((PPVExist[2]&PPVExist[3])==true)
         m_productiveVector2[4][5] = true; //bypass when flit2 is routed to productive port.
   }

   
   // Check flit 5
   if (PPVExist[5]==false && (m_pipelineReg1[5] != 0))
   {
      if ((PPVExist[2]&&PPVExist[3]&&PPVExist[4])==true)
         m_productiveVector2[5][5] = true; //bypass when flit2 is routed to productive port.
      else
      {
         for (outPort = m_ports-2; outPort >= 1; outPort--) // not including bypass and local port
         {
            if (availablePV[outPort]==true)
            {
               m_productiveVector2[5][outPort] = true;
               break;          
            }
         }
      }  
   }
   
   delete [] PPVExist;
   delete [] availablePV;
}




void TPZSimpleRouterFlowBless :: ejectLocal()
{
   unsigned index;
   for (index=1; index <= m_ports-1; index++) // only check channel 1-5
   {
      if (m_productiveVector2[index][6]==true && m_pipelineReg1[index]!=0)
      {
         //only one flit can be removed.
         outputInterfaz(6)->sendData(m_pipelineReg1[index]);
         m_pipelineReg1[index] = 0;
         m_productiveVector2[index][6]==false; // although local destined flit only has 1 productive port, it is always better to reset all 6 bits later.
         break;
      }
   }
}


void TPZSimpleRouterFlowBless ::computePVBypass (TPZMessage* msg)
{
   unsigned inPort, outPort;
   
   // get the current unallocated ports
   Boolean * availablePV = new Boolean [m_ports+1];
   for   (outPort=1; outPort < m_ports+1; outPort++)
   {
      availablePV[outPort] = false;
      for (inPort=1; inPort <= m_ports-2; inPort++)
         availablePV[outPort] = m_productiveVector2[inPort][outPort] | availablePV[outPort];
      availablePV[outPort] = !availablePV[outPort];
      if ((getDeltaAbs(msg, outPort) && availablePV[outPort])==true)
         m_productiveVector2[m_ports-1][outPort] = true;
      else
         m_productiveVector2[m_ports-1][outPort] = false;
   }
      
   delete availablePV;
}

void TPZSimpleRouterFlowBless :: injectBypass()
{
   if (m_sync[m_ports-1])
   {
      m_pipelineReg1[m_ports-1] = m_sync[m_ports-1];
      routeComputation(m_pipelineReg1[m_ports-1]);
      computePVBypass(m_pipelineReg1[m_ports-1]);
      //computePV2(m_pipelineReg1[m_ports-1],m_ports-1);
      m_sync[m_ports-1]=0;
   }
}

Boolean TPZSimpleRouterFlowBless :: injectLocal()
{

   //********************************************************************************************************
   // check the local injection and put the flit into injection queue.
   // Those comming from injection only move forward if one input port is free
   //*****************************************************************************************************s])
   if(m_sync[m_ports])
   {
      m_injectionQueue.enqueue(m_sync[m_ports]);
      m_sync[m_ports]=0;
   }

   if (m_injectionQueue.numberOfElements() !=0)
   {
      unsigned index;
      for (index=1; index<=m_ports-1; index++) // check channel 1-5
      {
         if (m_pipelineReg1[index])
            continue;
         m_injectionQueue.dequeue(m_pipelineReg1[index]); // not actual put into pipeline reg
         routeComputation(m_pipelineReg1[index]);
         computePV2(m_pipelineReg1[index],index);
         break;
      }
   }

   if (m_injectionQueue.numberOfElements() !=0) inputInterfaz(m_ports)->sendStopRightNow();
   else inputInterfaz(m_ports)->clearStopRightNow();
}

void  TPZSimpleRouterFlowBless :: sendFlit()
{
   unsigned index, outPort;
   Boolean outObtained;

   for (index=1; index<=m_ports-1; index++) // channel 1-5
   {
      outObtained = true;
      if (m_pipelineReg1[index])
      {
         debugStop(m_pipelineReg1[index]->getIdentifier(),m_pipelineReg1[index]->flitNumber(),getComponent().asString());
         
         outObtained = false;
         for ( outPort = 1; outPort <= m_ports-1; outPort++) // outPort 1-5; local has been removed.
         {
            if (m_productiveVector2[index][outPort]==true)
            {
               outputInterfaz(outPort)->sendData(m_pipelineReg1[index]);
               outObtained=true;
               break; //break outPort loop
            }
         }
      }
      
      // This is just for precaution.
      if (outObtained==false)
      {
         TPZString err;
         err.sprintf("%s :Pkt %u Flit %u did not find output port on channel %u", (char*)getComponent().asString(), m_pipelineReg1[index]->getIdentifier(), m_pipelineReg1[index]->flitNumber(), index);
         EXIT_PROGRAM(err);
      }
   }
}

void TPZSimpleRouterFlowBless :: clearPipeline1 ()
{
   unsigned inPort, outPort;
   for( inPort = 1; inPort <= m_ports-2; inPort++) // channel 1-4
   {
      m_sync[inPort] = 0;
      for ( outPort = 1; outPort < m_ports+1; outPort++) // outPort 1-5; local has been removed.
         m_productiveVector1[inPort][outPort] = false;
   }
}

void TPZSimpleRouterFlowBless :: clearPipeline2 ()
{
   unsigned inPort, outPort;
   for( inPort = 1; inPort < m_ports+1; inPort++) // channel 1-5
   {
      m_pipelineReg1[inPort] = 0;
      for ( outPort = 1; outPort < m_ports+1; outPort++) 
         m_productiveVector2[inPort][outPort] = false;
   }
}


void TPZSimpleRouterFlowBless :: pipelining()
{
   unsigned inPort, outPort;
   for( inPort = 1; inPort <= m_ports-2; inPort++) // channel 1-4
   {
      if (m_sync[inPort])
      {
         m_pipelineReg1[inPort] = m_sync[inPort];
         for ( outPort = 1; outPort < m_ports+1; outPort++) // outPort 1-5; local has been removed.
            m_productiveVector2[inPort][outPort] = m_productiveVector1[inPort][outPort];
      }
   }
}

void TPZSimpleRouterFlowBless :: permutationNetwork()
{
   Boolean swapEnable [2] = {false, false};

   // Stage 1
   swapEnable[0] = swapCtrl (m_sync[1], m_sync[2], m_productiveVector1[1], m_productiveVector1[2], 0);
   swapEnable[1] = swapCtrl (m_sync[3], m_sync[4], m_productiveVector1[3], m_productiveVector1[4], 1);
   resolveConflict (m_productiveVector1[1], m_productiveVector1[2], m_previousPV[1], m_previousPV[2], swapEnable[0], 0, 1);
   resolveConflict (m_productiveVector1[3], m_productiveVector1[4], m_previousPV[3], m_previousPV[4], swapEnable[1], 1, 1);
      // swap: data, PV, and previousPV; PV and previousPV can be directly set in RTL level to reduce cost.
   swapMsg(m_sync[1], m_sync[2], swapEnable[0]);
   swapPV(m_productiveVector1[1], m_productiveVector1[2], swapEnable[0]);
   swapPV(m_previousPV[1], m_previousPV[2], swapEnable[0]);
   swapMsg(m_sync[3], m_sync[4], swapEnable[1]);
   swapPV(m_productiveVector1[3], m_productiveVector1[4], swapEnable[1]);
   swapPV(m_previousPV[3], m_previousPV[4], swapEnable[1]);

   // stage 2
   swapEnable[0] = swapCtrl (m_sync[1], m_sync[3], m_productiveVector1[1], m_productiveVector1[3], 0);
   swapEnable[1] = swapCtrl (m_sync[2], m_sync[4], m_productiveVector1[2], m_productiveVector1[4], 0);
   resolveConflict (m_productiveVector1[1], m_productiveVector1[3], m_previousPV[1], m_previousPV[3], swapEnable[0], 0, 2);
   resolveConflict (m_productiveVector1[2], m_productiveVector1[4], m_previousPV[2], m_previousPV[4], swapEnable[1], 0, 2);
      // swap: data, PV, and previousPV; PV and previousPV can be directly set in RTL level to reduce cost.
   swapMsg(m_sync[1], m_sync[3], swapEnable[0]);
   swapPV(m_productiveVector1[1], m_productiveVector1[3], swapEnable[0]);
   swapPV(m_previousPV[1], m_previousPV[3], swapEnable[0]);
   swapMsg(m_sync[2], m_sync[4], swapEnable[1]);
   swapPV(m_productiveVector1[2], m_productiveVector1[4], swapEnable[1]);
   swapPV(m_previousPV[2], m_previousPV[4], swapEnable[1]);

   // stage 3
   swapEnable[0] = swapCtrl (m_sync[1], m_sync[2], m_productiveVector1[1], m_productiveVector1[2], 0);
   swapEnable[1] = swapCtrl (m_sync[3], m_sync[4], m_productiveVector1[3], m_productiveVector1[4], 0);
   resolveConflict (m_productiveVector1[1], m_productiveVector1[2], m_previousPV[1], m_previousPV[2], swapEnable[0], 0, 2); // the stage field function only for the bottom PN module of the 3rd stage. here, stage=2 is dummy.
   resolveConflict (m_productiveVector1[3], m_productiveVector1[4], m_previousPV[3], m_previousPV[4], swapEnable[1], 0, 3); // the stage field function only for the bottom PN module of the 3rd stage.
      // swap: data, PV, and previousPV; PV and previousPV can be directly set in RTL level to reduce cost.
   swapMsg(m_sync[1], m_sync[2], swapEnable[0]);
   swapPV(m_productiveVector1[1], m_productiveVector1[2], swapEnable[0]);
   swapPV(m_previousPV[1], m_previousPV[2], swapEnable[0]);
   swapMsg(m_sync[3], m_sync[4], swapEnable[1]);
   swapPV(m_productiveVector1[3], m_productiveVector1[4], swapEnable[1]);
   swapPV(m_previousPV[3], m_previousPV[4], swapEnable[1]);
}

void TPZSimpleRouterFlowBless :: swapMsg (TPZMessage* & msg0, TPZMessage* & msg1, Boolean swapEnable)
{
   TPZMessage* tempMsg;
   if (swapEnable == true)
   {
      tempMsg = msg0;
      msg0 = msg1;
      msg1 = tempMsg;
   }
}

void TPZSimpleRouterFlowBless :: swapPV (Boolean* & PV0, Boolean* & PV1, Boolean swapEnable)
{
   Boolean * tempPV;
   if (swapEnable == true)
   {
      tempPV = PV0;
      PV0 = PV1;
      PV1 = tempPV;
   }
}

//*************************************************************************
//:
//  f: unsigned resolveConflict (Boolean * PV0, Boolean * PV1, Boolean * previousPV0, Boolean * previousPV1, Boolean swapEnable)
//
//  d: For high priority flit, pick non-conflicted port if exists. If not, use the original PV.
//     For low priority flit, mask out the port picked by the other high priority flit.
//*************************************************************************

void  TPZSimpleRouterFlowBless :: resolveConflict (Boolean * &PV0, Boolean * &PV1, Boolean * &previousPV0, Boolean * &previousPV1, Boolean swapEnable, unsigned mode, unsigned stage)
{
   Boolean * conflictFreePV = new Boolean [m_ports+1];
   Boolean * PPV0 = new Boolean [m_ports+1]; // Prefered Productive Vector
   Boolean * PPV1 = new Boolean [m_ports+1];
   Boolean PPV0Exist = false;
   Boolean PPV1Exist = false;
   //unsigned index;

   for (int i=1; i < m_ports+1; i++) //must resolve conflict on all ports, including local
   {
      conflictFreePV[i] = !(PV0[i] & PV1[i]);
      PPV0[i] = conflictFreePV[i] & PV0[i]; // mask out the conflicted port
      PPV1[i] = conflictFreePV[i] & PV1[i]; // mask out the conflicted port
      PPV0Exist = PPV0Exist | PPV0[i];
      PPV1Exist = PPV1Exist | PPV1[i];
   }
      // swapEnable == false/true : PV0/PV1 has higher priority; swapEnable is just to indicate the priority. No swap here.
      // Use the transitive property to mask out the conflicted ports against the competing flit and the competing flit of the previous flit.
      // For wining flit, previousPV[i] = false;
      // For losing flit, previousPV[i] = PV[i] of the wining flit.

   for (int i=1; i < m_ports+1; i++)
   {
      if ((swapEnable == false && mode == 0) || (swapEnable == true && mode == 1)) //flit0 has higher priority
      {
         // update PV
         // For wining flit of stage 1&2, choose PPV if exist. for the bottom permuter block at the stage3, must mask out the previousPV as well (since all 2 flits above have higher priority).
         if (stage != 3)
            PV0[i] = PPV0Exist ? PPV0[i] : PV0[i];
         else // = 3
            PV0[i] = PPV0Exist ? (PPV0[i]& !previousPV1[i]) : (PV0[i]& !previousPV1[i]);
         
            PV1[i] = PPV0Exist ? (!PPV0[i] & !previousPV0[i] & PV1[i]) : (!PV0[i] & !previousPV0[i] & PV1[i]);
        
         // Update previousPV
         previousPV0[i] = false;
         previousPV1[i] = PV0[i];
      }
      else if ((swapEnable == false && mode == 1) || (swapEnable == true && mode == 0))
      {
         if (stage != 3)
            PV1[i] = PPV1Exist ? PPV1[i] : PV1[i];
         else
            PV1[i] = PPV1Exist ? (PPV1[i] & !previousPV0[i]) : (PV1[i] & !previousPV0[i]);
         
            PV0[i] = PPV1Exist ? (!PPV1[i] & !previousPV1[i] & PV0[i]) : (!PV1[i] & !previousPV1[i] & PV0[i]);
        
         previousPV1[i] = false;
         previousPV0[i] = PV1[i];
      }
   }

   delete [] conflictFreePV;
   delete [] PPV0;
   delete [] PPV1;
}


//*************************************************************************
//:
//  f: unsigned swapCtrl (TPZMessage * msg0, TPZMessage * msg1, Boolean * PV0, Boolean * PV1, unsigned mode)
//
//  d: determine if swap the flits or not.
//*************************************************************************
Boolean  TPZSimpleRouterFlowBless :: swapCtrl (TPZMessage * msg0, TPZMessage * msg1, Boolean * PV0, Boolean * PV1, unsigned mode)
{
   // mode 0: upward 1: downward
   Boolean hasPV0 = false;
   Boolean hasPV1 = false;
   unsigned index;

   for (index=1; index<m_ports+1; index++)
   {
      hasPV0 = hasPV0 | PV0[index];
      hasPV1 = hasPV1 | PV1[index];
   }
   
   
   //   Strictly honor oldest first
   
   if ((msg0 == 0 && msg1 == 0) )
      return false;
   else if (msg0 == 0 && msg1 != 0)
   {
      // msg1 has higher priority
      if (mode == 0)
         return true;
      else if (mode == 1)
         return false;
   }
   else if (msg0 != 0 && msg1 == 0)
   {
      if (mode == 0)
         return false;
      else if (mode == 1)
         return true;
   }
   else 
   {
      unsigned timeGen0, timeGen1;
      timeGen0 = msg0->generationTime();
      timeGen1 = msg1->generationTime();
      if (timeGen0 > timeGen1)
      {
         // msg1 is older.
         if (mode == 0)
            return true;
         else if (mode == 1)
            return false;
      }
      else if (timeGen0 == timeGen1)
      {  
         if (hasPV0)
         {
            if (mode == 0)
               return false;
            else if (mode == 1)
               return true;
         }      
         else
         {
            if (mode == 0)
               return true;
            else if (mode == 1)
               return false;
         }       
      }
      else
      {
         if (mode == 0)
            return false;
         else if (mode == 1)
            return true;
      }
   }
}


void TPZSimpleRouterFlowBless ::computePV2 (TPZMessage* msg, unsigned index)
{
   unsigned inPort, outPort;
   Boolean found = false;
   Boolean * availablePV = new Boolean [m_ports+1];
   
   debugStop(msg->getIdentifier(),  msg->flitNumber(), getComponent().asString());
   
   for   (outPort=1; outPort < m_ports; outPort++) // port 1-5
   {
      availablePV[outPort] = false;
      for (inPort=1; inPort < m_ports; inPort++) // channel 1-5
         availablePV[outPort] = m_productiveVector2[inPort][outPort] | availablePV[outPort];
      availablePV[outPort] = !availablePV[outPort];
      if (getDeltaAbs(msg, outPort) && availablePV[outPort])
      {
         m_productiveVector2[index][outPort] = true;
         found = true;
         break;
      }
   }

   if (found == false)
   {
      for   (outPort=1; outPort < m_ports; outPort++) // port 1-5
      {
         if (availablePV[outPort])
         {
            m_productiveVector2[index][outPort] = true;
            found = true;
            break;
         }
      }
   }

   if (found == false)
   {
      TPZString err;
      err.sprintf("Error: TPZSimpleRouterFlowBless :: computePV2 --- %s :Pkt %u Flit %u did not find output port on channel %u", (char*)getComponent().asString(), msg->getIdentifier(), msg->flitNumber(), index);
      EXIT_PROGRAM(err);
   }

   delete [] availablePV;
}

void TPZSimpleRouterFlowBless ::computePV1 (TPZMessage* msg, unsigned index)
{
   unsigned outPort;
   for ( outPort = 1; outPort < m_ports+1; outPort++)
   {
      if (getDeltaAbs(msg, outPort)==true)
         m_productiveVector1[index][outPort] = true;
      else
         m_productiveVector1[index][outPort] = false;
   }
}

Boolean TPZSimpleRouterFlowBless :: routeComputation(TPZMessage* msg)
{
   int deltaX;
   int deltaY;
   int deltaZ;

   TPZPosition source= getOwnerRouter().getPosition();
   TPZPosition destination=msg->destiny();
   // A: This is the actual routing.
   //    routingRecord () will be overloaded based on the type of network.
   ((TPZNetwork*)getOwnerRouter().getOwner())->routingRecord(source,destination,deltaX,deltaY,deltaZ);
   // A: Header manipulation.
   msg->setDelta(deltaX,0);
   msg->setDelta(deltaY,1);
   msg->setDelta(deltaZ,2);
   return true;
}

//*************************************************************************
//:
//  f: unsigned getDeltaAbs(TPZMessage* msg, unsigned outPort);
//
//  d: // A: check if "outPort" is the desired output port for "msg".
       // Return "true" is yes.
//*************************************************************************
Boolean TPZSimpleRouterFlowBless :: getDeltaAbs(TPZMessage* msg, unsigned outPort)
{
   //the order in sgml file must fit the same one as the selected for this file
   //this means: 1-(x+) 2-(x-) 3-(y+) 4-(y-) 5-(Node)
   int deltaX=msg->delta(0);
   int deltaY=msg->delta(1);
   int deltaZ=msg->delta(2);
#ifndef NO_TRAZA
   TPZString texto4 = getComponent().asString() + " Checking Delta = ";
   texto4 += TPZString(deltaX) + " " + TPZString(deltaY) + " " + TPZString(deltaZ) + " "  + msg->asString() ;
   texto4 += TPZString(((TPZSimpleRouter&)getComponent()).getTypeForOutput(outPort));
   TPZWRITE2LOG(texto4);
#endif

   TPZROUTINGTYPE tipo;

   //if (outPort > 4)
   //   tipo=((TPZSimpleRouter&)getComponent()).getTypeForOutput(outPort-4);
   //else
      tipo=((TPZSimpleRouter&)getComponent()).getTypeForOutput(outPort);

   // A: check if "outPort" is the desired output port.
   // Return "true" is yes.
   switch(tipo)
   {
      case _Xplus_:
         if (deltaX>1) return true;
	     else return false;
	     break;
      case _Xminus_:
         if (deltaX<-1) return true;
	     else return false;
	     break;
      case _Yplus_:
         if (deltaY>1) return true;
	     else return false;
	     break;
      case _Yminus_:
         if (deltaY<-1) return true;
	     else return false;
	     break;
      case _Zplus_:
         if (deltaZ>1) return true;
	     else return false;
	     break;
      case _Zminus_:
         if (deltaZ<-1) return true;
	     else return false;
	     break;
      case _ByPass_:  // During port allocation, this bypass will not be selected.
         return false;
        break;
      case _LocalNode_:
         if ( (deltaX==1 || deltaX==-1) && (deltaY==1 || deltaY==-1) && (deltaZ==1 || deltaZ==-1) ) return true;
	     else return false;
	     break;


      default:
         TPZString err;
	     err.sprintf("%s :output port out of range", (char*)getComponent().asString() );
	     EXIT_PROGRAM(err);
	 break;
   }

}

//*************************************************************************
//:
//  f: virtual Boolean updateMessageInfo(TPZMessage& msg, unsigned outPort);
//
//  d: (By Anderson) update port allocation result
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: updateMessageInfo(TPZMessage* msg, unsigned outPort)
{
   int deltaX;
   int deltaY;
   int deltaZ;

   // A: get the network size
   unsigned SizeX= ((TPZNetwork*)getOwnerRouter().getOwner())->getSizeX();
   unsigned SizeY= ((TPZNetwork*)getOwnerRouter().getOwner())->getSizeY();
   unsigned SizeZ= ((TPZNetwork*)getOwnerRouter().getOwner())->getSizeZ();

   // A: get the position of the current node.
   //    source seems to be updated each hop.
   TPZPosition source= getOwnerRouter().getPosition();
   int PosX=source.valueForCoordinate(TPZPosition::X);
   int PosY=source.valueForCoordinate(TPZPosition::Y);
   int PosZ=source.valueForCoordinate(TPZPosition::Z);

   // A: get the destination of the msg.
   TPZPosition destination=msg->destiny();

   TPZROUTINGTYPE tipo;

   //if (outPort > 4)
   //   tipo=((TPZSimpleRouter&)getComponent()).getTypeForOutput(outPort-4);
   //else
      tipo=((TPZSimpleRouter&)getComponent()).getTypeForOutput(outPort);

   // A: update the position of next hop based on the routing algorithm
   switch(tipo)
   {
      case _Xplus_:
         PosX= (PosX+1)%SizeX;
	     msg->setRoutingPort(_Xplus_);
	     break;
      case _Xminus_:
         PosX= (PosX+(SizeX-1))%SizeX;
	     msg->setRoutingPort(_Xminus_);
	     break;
      case _Yplus_:
         PosY= (PosY+1)%SizeY;
         msg->setRoutingPort(_Yplus_);
	     break;
      case _Yminus_:
         PosY=(PosY+(SizeY-1))%SizeY;
         msg->setRoutingPort(_Yminus_);
	     break;
      case _Zplus_:
         PosZ= (PosZ+1)%SizeZ;
         msg->setRoutingPort(_Zplus_);
	     break;
      case _Zminus_:
         PosZ=(PosZ+(SizeZ-1))%SizeZ;
         msg->setRoutingPort(_Zminus_);
	     break;
      case _LocalNode_:
         msg->setRoutingPort(_LocalNode_);
	     break;
      case _ByPass_:  // In this case, the value of delta does not update.
         msg->setRoutingPort(_ByPass_);
        break;

      default:
         TPZString err;
	     err.sprintf("%s :output port out of range", (char*)getComponent().asString() );
	     EXIT_PROGRAM(err);
	     break;
   }
   // A: source information is updated.
   source.setValueAt(TPZPosition::X, PosX);
   source.setValueAt(TPZPosition::Y, PosY);
   source.setValueAt(TPZPosition::Z, PosZ);

   // A: This might be the actual routing.
   //    routingRecord () will be overloaded based on the type of network.
   ((TPZNetwork*)getOwnerRouter().getOwner())->routingRecord(source,destination,deltaX,deltaY,deltaZ);

   // A: Header manipulation.
   msg->setDelta(deltaX,0);
   msg->setDelta(deltaY,1);
   msg->setDelta(deltaZ,2);

   return true;
}

//*************************************************************************
//:
//  f: virtual Boolean stateChange();
//
//  d:
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: stateChange()
{
   return true;
}


//*************************************************************************
//:
//  f: virtual Boolean outputWriting();
//
//  d:
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: outputWriting()
{
   return true;
}

//*************************************************************************
//:
//  f: virtual Boolean dispatchEvent(const TPZEvent& event);
//
//  d:
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: dispatchEvent(const TPZEvent& event)
{
   return true;
}

//*************************************************************************
//:
//  f: void cleanOutputInterfaces();
//
//  d:
//:
//*************************************************************************

void TPZSimpleRouterFlowBless :: cleanOutputInterfaces()
{
   if( cleanInterfaces() )
   {
      unsigned i,j;
      TPZSimpleRouter& simpleRouter = (TPZSimpleRouter&)getComponent();

      forInterfaz(i,simpleRouter.numberOfOutputs())
      {
         forInterfaz(j,outputInterfaz(i)->numberOfCV() )
            outputInterfaz(i)->clearData(j);
      }
   }
}

//*************************************************************************
//:
//  f: void cleanInputInterfaces();
//
//  d:
//:
//*************************************************************************

void TPZSimpleRouterFlowBless :: cleanInputInterfaces()
{
   if( cleanInterfaces() )
   {
      unsigned i,j;
      TPZSimpleRouter& simpleRouter = (TPZSimpleRouter&)getComponent();
      forInterfaz(i,simpleRouter.numberOfInputs())
      {
          // A: CV probably is 1 in BLESS since there is only 1 virtual channel at each port.
          forInterfaz(j,outputInterfaz(i)->numberOfCV() )
            inputInterfaz(i)->clearStop(j);
      }
   }
}

//*************************************************************************
//:
//  f: virtual Boolean controlAlgoritm(Boolean info=false, int delta=0);
//
//  d:
//:
//*************************************************************************

// A: I don't know what it is.
Boolean TPZSimpleRouterFlowBless :: controlAlgoritm(Boolean info, int delta)
{
   // Para evitar que sea una clase abstracta.
   return true;
}


//*************************************************************************
//:
//  f: virtual Boolean onReadyUp(unsigned interfaz, unsigned cv);
//
//  d:
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: onReadyUp(unsigned interfaz, unsigned cv)
{
   TPZMessage* msg;
   inputInterfaz(interfaz)->getData(&msg);
   msg->incDistance(); // A: why?
   m_sync[interfaz]=msg;
 #ifndef NO_TRAZA
   TPZString texto4 = getComponent().asString() + " Message arriving = ";
   texto4 += msg->asString() ;
   TPZWRITE2LOG(texto4);
#endif
   return true;
}


//*************************************************************************
//:
//  f: virtual Boolean onStopUp(unsigned interfaz, unsigned cv);
//
//  d:
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: onStopUp(unsigned interfaz, unsigned cv)
{
   return true;
}


//*************************************************************************
//:
//  f: virtual Boolean onStopDown(unsigned interfaz, unsigned cv);
//
//  d:
//:
//*************************************************************************

Boolean TPZSimpleRouterFlowBless :: onStopDown(unsigned interfaz, unsigned cv)
{
   return true;
}

//*************************************************************************
//:
//  f: TPZString getStatus() const;
//
//  d:
//:
//*************************************************************************

TPZString TPZSimpleRouterFlowBless :: getStatus() const
{
   TPZSimpleRouter& crb = (TPZSimpleRouter&)getComponent();
   TPZString rs = crb.asString() + TPZString(":\tIn stop= ");

   int i, channel;
   for( i=1; i<=crb.numberOfInputs(); i++ )
   {
      if( inputInterfaz(i)->isStopActive() )
         rs+= TPZString("I") + TPZString(i) + " ";
   }
   rs += TPZString(".\tOut stop= ");
   for( i=1; i<=crb.numberOfOutputs(); i++ )
   {
      if( crb.isLocalNodeOutput(i) )
      {
         if( outputInterfaz(i)->isStopActive() )
            rs+= TPZString("O") + TPZString(i) + " ";
      }

      else
      {
         channel=1;
         if( outputInterfaz(i)->isStopActive(channel) )
            rs+= TPZString("O") + TPZString(i) + TPZString(channel) + " ";
      }
   }

   return rs;
}

//*************************************************************************


// end of file
