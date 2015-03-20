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

void TPZSimpleRouterFlowBless :: initialize()
{
   Inhereited :: initialize();

   m_ports=((TPZSimpleRouter&)getComponent()).numberOfInputs();
   m_connections=new unsigned[m_ports+1];
   m_sync=new TPZMessage*[m_ports+1];
   m_connEstablished=new Boolean[m_ports+1];

   for(int i=0; i<m_ports+1; i++)
   {
      m_connections[i] = 0;
      m_connEstablished[i] = false;
      m_sync[i]=0;
   }

   setCleanInterfaces(true);
}

unsigned NUM_LOCAL_PORT = 1;

//*************************************************************************
//:
//  f: virtual void terminate();
//
//  d:
//:
//*************************************************************************

void TPZSimpleRouterFlowBless :: terminate()
{
   delete[] m_connections;
   delete[] m_sync;
   delete[] m_connEstablished;
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
   
 
   
   cleanOutputInterfaces();

   //**********************************************************************************************************
   // PART1: move through all the sync (except injection, which has special treatment).
   // Put every message arrived into the only queue, ordered according to their priority (age)
   //**********************************************************************************************************
   for( inPort = 1; inPort <= m_ports-NUM_LOCAL_PORT; inPort++)
   {
      // If there is a message at sync,
      if(m_sync[inPort])
      {
        // Anderson: may change the implementation.
        // I don't need a priority queue.
        // two stage arbitration may be implemented here.
        uTIME timeGen=m_sync[inPort]->generationTime(); // Anderson: get the time stamp information of each arrival flits
        m_priorityQueue.enqueue(m_sync[inPort], timeGen); // Anderson: add into the priorityQueue.

#ifndef NO_TRAZA
		TPZString texto = getComponent().asString() + " Message at Sync. TIME = ";
		texto += TPZString(getOwnerRouter().getCurrentTime()) + " # " + "iPort=" + TPZString(inPort) + m_sync[inPort]->asString() ;
		TPZWRITE2LOG(texto);
#endif
         m_sync[inPort]=0;
      }
   }

   // A: check the local injection and put the flit into injection queue.
   //    The injection queue should reside in NI.
   //    bypass may be added here.
   // Those comming from injection only move forward if one input port is free
   //********************************************************************************************************
   
   // queue the flit with large index first
   // so if there are two flits in the injectionQ, the head flit is from the port with small index
   for (int i=0; i< NUM_LOCAL_PORT; i++)
   {
      if(m_sync[m_ports-i])
      {
         m_injectionQueue.enqueue(m_sync[m_ports-i]);
         #ifndef NO_TRAZA
         TPZString texto2 = getComponent().asString() + " Message at Sync. TIME = ";
         texto2 += TPZString(getOwnerRouter().getCurrentTime()) + " # " + "iPort=" + TPZString(m_ports-i) + m_sync[m_ports-i]->asString() ;
         TPZWRITE2LOG(texto2);
         #endif
         m_sync[m_ports-i]=0;
      }  
   }
   
   /*
      allow injection if #_arrival_input < #_port - #_localPort; (make sure no deadlock
   */
   
   for (int i=NUM_LOCAL_PORT-1; i>=0; i--)
   {
      // remove flit with small index first.
      if( (m_priorityQueue.numberOfElements() < (m_ports-NUM_LOCAL_PORT)) && (m_injectionQueue.numberOfElements() !=0) )
      {
        TPZMessage* msg;
        m_injectionQueue.dequeue(msg); // Anderson: construct a outstanding msg.
        uTIME timeGen=msg->generationTime();
        m_priorityQueue.enqueue(msg, timeGen); // Anderson: put into the only priorityQueue.
        // Anderson: although the newly injected flit will always has the lowest priority, it is also needed since msg is only retrieved from the head of a shared priorityQueue.
      }     
       
      if (m_injectionQueue.numberOfElements() !=0) inputInterfaz(m_ports-i)->sendStopRightNow();
      else inputInterfaz(m_ports-i)->clearStopRightNow();
   }
      

 
   
   //**********************************************************************************************************
   // PART2: Empty message queue
   // It must remain completely empty, every message must find an output port.
   //**********************************************************************************************************
   // A: Here, the connection is released after sending each flit.
   // A: modify: each connection will be released at the unit of each packet.

   for( outPort=1; outPort<=m_ports; outPort++)
   {
      m_connEstablished[outPort] = false;
   }

   while ( m_priorityQueue.numberOfElements() != 0 )
   {
      TPZMessage* msg;  // A: construct a msg
      m_priorityQueue.dequeue(msg); // A: consume a msg in the priorityQueue

      Boolean outObtained=false;
      Boolean deflected=true;   // A: why deflect the flit by default?

     /*
     if (msg->getIdentifier() == 3 && msg->flitNumber() == 5)
      {
         cout << "Time is " << getOwnerRouter().getCurrentTime() << endl;
         cout << "We are at " << getComponent().asString() << endl;
      }
      */
      
      // A: try to find an available output port.
      for ( outPort = 1; outPort <= m_ports; outPort++)
      {
         if (getDeltaAbs(msg, outPort)==true && m_connEstablished[outPort]==false)
	     {
	        m_connEstablished[outPort]=true;
	        updateMessageInfo(msg, outPort);
	        ((TPZNetwork*)(getOwnerRouter().getOwner()))->incrEventCount( TPZNetwork::SWTraversal);
	        if ( outPort!=m_ports) // A: not local-bound traffic
            {
               ((TPZNetwork*)(getOwnerRouter().getOwner()))->incrEventCount( TPZNetwork::LinkTraversal);
               getOwnerRouter().incrLinkUtilization();// by Anderson
	        }
	        outputInterfaz(outPort)->sendData(msg);
	        #ifndef NO_TRAZA
               TPZString texto3 = getComponent().asString() + " Routed TIME = ";
               texto3 += TPZString(getOwnerRouter().getCurrentTime()) + " # " + "oPort=" + TPZString(outPort) + msg->asString() ;
               TPZWRITE2LOG(texto3);
            #endif
	        deflected=false;
	        outObtained=true;
	        break;
	      }
       }
      
      /*
         did not find an available output port. Deflection occurs.
         In this case, deflect the flit to an unallocated port.
         Notice that, deflect to consumers is not accepted.
         So, be aware of the outPort range.
      */
      if (deflected==true)
      {
         for ( outPort = 1; outPort <= m_ports-NUM_LOCAL_PORT; outPort++)
         {
            if (m_connEstablished[outPort]==false)
            {
                m_connEstablished[outPort]=true;
                updateMessageInfo(msg, outPort);
                ((TPZNetwork*)(getOwnerRouter().getOwner()))->incrEventCount( TPZNetwork::SWTraversal);
                ((TPZNetwork*)(getOwnerRouter().getOwner()))->incrEventCount( TPZNetwork::LinkTraversal);
                outputInterfaz(outPort)->sendData(msg);
                #ifndef NO_TRAZA
                    TPZString texto4 = getComponent().asString() + " Deflected TIME = ";
                    texto4 += TPZString(getOwnerRouter().getCurrentTime()) + " # " + "oPort=" + TPZString(outPort) + msg->asString() ;
                    TPZWRITE2LOG(texto4);
                #endif
                outObtained=true;
                break;
            }
        }
      }

 
      // A: This is just for precaution.
      if (outObtained==false)
      {
         TPZString err;
         err.sprintf("%s :One message did not find output port", (char*)getComponent().asString() );
         EXIT_PROGRAM(err);
      }

   }



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
